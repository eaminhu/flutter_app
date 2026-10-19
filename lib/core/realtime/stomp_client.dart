import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Minimal SockJS (websocket-only transport) + STOMP 1.2 client for the v1
/// realtime feeds. Verified against dev by tool/ws_probe.dart:
/// server sends `o` on open, messages as `a["<stomp frame>"]`, and the
/// STOMP-level heartbeat as `a["\n"]` every 15s (heart-beat 15000,15000).
///
/// Pure Dart (dart:io only); frame codecs are top-level pure functions.

// ─── SockJS frame codec ────────────────────────────────────────────────────

sealed class SockJsEvent {
  const SockJsEvent();
}

class SockJsOpen extends SockJsEvent {
  const SockJsOpen();
}

class SockJsMessages extends SockJsEvent {
  const SockJsMessages(this.frames);
  final List<String> frames;
}

class SockJsHeartbeat extends SockJsEvent {
  const SockJsHeartbeat();
}

class SockJsClose extends SockJsEvent {
  const SockJsClose(this.frame);
  final String frame;
}

/// Client→server payload: a JSON array of STOMP frame strings.
String sockJsEncode(List<String> frames) => jsonEncode(frames);

SockJsEvent? sockJsDecode(String frame) {
  if (frame == 'o') return const SockJsOpen();
  if (frame == 'h') return const SockJsHeartbeat();
  if (frame.startsWith('c')) return SockJsClose(frame);
  if (frame.startsWith('a')) {
    final decoded = jsonDecode(frame.substring(1));
    if (decoded is! List) return null;
    return SockJsMessages([for (final f in decoded) '$f']);
  }
  return null;
}

// ─── STOMP frame codec ─────────────────────────────────────────────────────

class StompFrame {
  const StompFrame(this.command, this.headers, this.body);
  final String command;
  final Map<String, String> headers;
  final String body;
}

String stompEncode(String command, [Map<String, String> headers = const {}, String body = '']) {
  final buffer = StringBuffer(command)..write('\n');
  headers.forEach((key, value) => buffer.write('$key:$value\n'));
  buffer.write('\n');
  if (body.isNotEmpty) buffer.write(body);
  buffer.write('\x00');
  return buffer.toString();
}

/// Null for a heartbeat (a bare newline) or an empty frame.
StompFrame? stompDecode(String text) {
  if (text.trim().isEmpty) return null;
  final headerEnd = text.indexOf('\n\n');
  if (headerEnd < 0) return null;
  final head = text.substring(0, headerEnd).split('\n');
  final command = head.first.trim();
  if (command.isEmpty) return null;
  final headers = <String, String>{};
  for (final line in head.skip(1)) {
    final colon = line.indexOf(':');
    if (colon > 0) headers[line.substring(0, colon)] = line.substring(colon + 1);
  }
  var body = text.substring(headerEnd + 2);
  if (body.endsWith('\x00')) body = body.substring(0, body.length - 1);
  return StompFrame(command, headers, body);
}

// ─── client ────────────────────────────────────────────────────────────────

class StompMessage {
  const StompMessage({required this.destination, required this.body});
  final String destination;
  final String body;
}

/// Reconnect policy: 5s delay, capped at 6 consecutive failures, reset on
/// success. Pure logic, unit-tested.
class ReconnectPolicy {
  ReconnectPolicy({this.delay = const Duration(seconds: 5), this.maxFailures = 6});

  final Duration delay;
  final int maxFailures;
  var failures = 0;

  /// True while another reconnect attempt is allowed.
  bool get canRetry => failures <= maxFailures;

  void recordFailure() => failures++;
  void recordSuccess() => failures = 0;
}

class StompClient {
  StompClient({
    required this.wsBase,
    this.policy,
    this.heartbeat = const Duration(seconds: 15),
  });

  /// SockJS base, e.g. wss://host/swap_market/ws (no trailing slash).
  final Uri wsBase;
  final ReconnectPolicy? policy;
  final Duration heartbeat;

  final _messages = StreamController<StompMessage>.broadcast();
  Stream<StompMessage> get messages => _messages.stream;

  final _subs = <String, String>{}; // subscription id → destination
  int _nextSubId = 0;

  WebSocket? _socket;
  bool _connecting = false;
  bool _connected = false;
  bool _disposed = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime _lastReceived = DateTime.fromMillisecondsSinceEpoch(0);
  late final ReconnectPolicy _policy = policy ?? ReconnectPolicy();

  bool get connected => _connected;

  /// Subscribes a destination, connecting lazily. Returns the subscription id.
  String subscribe(String destination) {
    final id = 'sub-${_nextSubId++}';
    _subs[id] = destination;
    if (_connected) {
      _send(stompEncode('SUBSCRIBE', {'id': id, 'destination': destination}));
    } else {
      unawaited(_ensureConnected());
    }
    return id;
  }

  void unsubscribe(String id) {
    if (_subs.remove(id) == null) return;
    if (_connected) _send(stompEncode('UNSUBSCRIBE', {'id': id}));
    if (_subs.isEmpty) _teardown();
  }

  /// App-resume hook: reconnect immediately when the socket is down.
  void revalidate() {
    if (_disposed || _connected || _connecting) return;
    _reconnectTimer?.cancel();
    unawaited(_ensureConnected());
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    if (_connected) {
      _send(stompEncode('DISCONNECT'));
    }
    await _socket?.close();
    _socket = null;
    _connected = false;
    await _messages.close();
  }

  Uri _socketUri() {
    final serverId = Random().nextInt(1000).toString().padLeft(3, '0');
    final session = Random().nextInt(1 << 31).toRadixString(36);
    return wsBase.resolve('$serverId/s$session/websocket');
  }

  Future<void> _ensureConnected() async {
    if (_connected || _connecting || _disposed || _subs.isEmpty) return;
    _connecting = true;
    try {
      final socket = await WebSocket.connect(
        _socketUri().toString(),
      ).timeout(const Duration(seconds: 10));
      _socket = socket;
      socket.listen(
        _onData,
        onError: (_) => _onSocketDown(),
        onDone: _onSocketDown,
      );
    } catch (_) {
      _connecting = false;
      _scheduleReconnect();
    }
  }

  void _onData(Object? event) {
    if (event is! String) return;
    _lastReceived = DateTime.now();
    final decoded = sockJsDecode(event);
    switch (decoded) {
      case SockJsOpen():
        _send(
          stompEncode('CONNECT', {
            'accept-version': '1.2',
            'heart-beat': '15000,15000',
          }),
        );
      case SockJsMessages(:final frames):
        for (final frame in frames) {
          _onStomp(frame);
        }
      case SockJsHeartbeat():
        break;
      case SockJsClose():
        _onSocketDown();
      case null:
        break;
    }
  }

  void _onStomp(String text) {
    final frame = stompDecode(text);
    if (frame == null) return; // STOMP heartbeat (a["\n"])
    switch (frame.command) {
      case 'CONNECTED':
        _connected = true;
        _connecting = false;
        _policy.recordSuccess();
        _startHeartbeat();
        // Re-subscribe everything after a (re)connect.
        _subs.forEach((id, destination) {
          _send(stompEncode('SUBSCRIBE', {'id': id, 'destination': destination}));
        });
      case 'MESSAGE':
        final destination = frame.headers['destination'];
        if (destination != null) {
          _messages.add(StompMessage(destination: destination, body: frame.body));
        }
      case 'ERROR' || 'RECEIPT':
        break;
    }
  }

  void _send(String stompFrame) {
    _socket?.add(sockJsEncode([stompFrame]));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeat, (_) {
      final socket = _socket;
      if (socket == null) return;
      // Outgoing STOMP heartbeat, SockJS-wrapped like every client frame.
      socket.add(sockJsEncode(['\n']));
      // Server heartbeats arrive every ~15s; allow one missed beat.
      if (DateTime.now().difference(_lastReceived) > heartbeat * 2 + const Duration(seconds: 5)) {
        _onSocketDown();
      }
    });
  }

  void _onSocketDown() {
    if (_disposed) return;
    _heartbeatTimer?.cancel();
    _connected = false;
    _connecting = false;
    final socket = _socket;
    _socket = null;
    unawaited(socket?.close().catchError((_) {}));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _subs.isEmpty) return;
    _policy.recordFailure();
    if (!_policy.canRetry) return; // capped: stop until revalidate()/dispose()
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_policy.delay, () => unawaited(_ensureConnected()));
  }

  void _teardown() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    final socket = _socket;
    _socket = null;
    _connected = false;
    _connecting = false;
    unawaited(socket?.close().catchError((_) {}));
  }
}
