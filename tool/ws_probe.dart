import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Protocol probe for the v1 prediction realtime feed (dev).
///
/// Verifies the SockJS (websocket-only transport) + STOMP handshake against
/// wss://dev-nexusft-trade-api.nexuspb.com/swap_market/ws/{serverId}/{session}/websocket
/// and subscribes one real marketId's /topic/pm/auction/{marketId} channel.
/// Prints every frame and exits on its own after 25s.
///
/// Run: D:\development\flutter\bin\dart.bat run tool/ws_probe.dart
Future<void> main() async {
  const host = 'dev-nexusft-trade-api.nexuspb.com';
  final sw = Stopwatch()..start();
  void log(String message) =>
      stdout.writeln('[${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s] $message');

  // 1. Find a real marketId from the public home feed.
  final http = HttpClient();
  String? marketId;
  try {
    final request = await http.getUrl(
      Uri.https(host, '/swap/pm/home', {'sort': 'soon', 'page': '1', 'pageSize': '5'}),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    log('home HTTP ${response.statusCode}, ${body.length} bytes');
    final decoded = jsonDecode(body);
    final items = decoded['data']?['markets']?['items'];
    if (items is List) {
      for (final item in items) {
        final preview = item['previewItems'];
        if (preview is List) {
          for (final p in preview) {
            final id = p['marketId'];
            if (id != null && '$id'.trim().isNotEmpty) {
              marketId = '$id';
              log('marketId=$marketId (event ${item['id']} "${item['title']}")');
              break;
            }
          }
        }
        if (marketId != null) break;
      }
    }
  } catch (error) {
    log('home fetch failed: $error');
  }
  if (marketId == null) {
    log('PROBE_FAIL no marketId');
    exit(2);
  }

  // 2. SockJS websocket-transport URL.
  final serverId = Random().nextInt(1000).toString().padLeft(3, '0');
  final session = Random()
      .nextInt(1 << 31)
      .toRadixString(36);
  final wsUrl = 'wss://$host/swap_market/ws/$serverId/probe$session/websocket';
  log('connecting $wsUrl');

  WebSocket socket;
  try {
    socket = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 10));
  } catch (error) {
    log('PROBE_FAIL websocket connect: $error');
    exit(2);
  }
  log('websocket open');

  final done = Completer<void>();
  Timer(const Duration(seconds: 40), () {
    log('timeout, closing');
    if (!done.isCompleted) done.complete();
  });

  var stompConnected = false;
  var auctionMessages = 0;

  void sendStomp(String frame) {
    final payload = jsonEncode([frame]);
    log('>> $payload');
    socket.add(payload);
  }

  socket.listen(
    (event) {
      if (event is! String) {
        log('<< binary ${event.length} bytes');
        return;
      }
      if (event == 'o') {
        log('<< o (sockjs open) — sending STOMP CONNECT');
        sendStomp('CONNECT\naccept-version:1.2\nheart-beat:15000,15000\n\n\x00');
        return;
      }
      if (event == 'h') {
        log('<< h (heartbeat)');
        return;
      }
      if (event.startsWith('a')) {
        final frames = jsonDecode(event.substring(1)) as List;
        for (final frame in frames) {
          final text = '$frame';
          final command = text.split('\n').first;
          log('<< STOMP $command ${text.length} chars');
          if (command == 'CONNECTED') {
            stompConnected = true;
            log('CONNECTED frame: ${text.replaceAll('\x00', '')}');
            log('STOMP CONNECTED — subscribing /topic/pm/auction/$marketId');
            sendStomp(
              'SUBSCRIBE\nid:sub-0\ndestination:/topic/pm/auction/$marketId\n\n\x00',
            );
          } else if (command == 'MESSAGE') {
            final body = text.split('\n\n').skip(1).join('\n\n');
            log('MESSAGE body: ${body.replaceAll('\x00', '')}');
            if (text.contains('/topic/pm/auction/')) auctionMessages++;
          } else if (command == 'ERROR') {
            log('STOMP ERROR frame: $text');
          }
        }
        return;
      }
      if (event.startsWith('c')) {
        log('<< c (sockjs close): $event');
        if (!done.isCompleted) done.complete();
        return;
      }
      log('<< unknown frame: $event');
    },
    onError: (Object error) {
      log('socket error: $error');
      if (!done.isCompleted) done.complete();
    },
    onDone: () {
      log('socket closed by peer');
      if (!done.isCompleted) done.complete();
    },
  );

  await done.future;
  await socket.close();
  http.close();
  log(stompConnected
      ? 'PROBE_RESULT stomp=connected auctionMessages=$auctionMessages'
      : 'PROBE_RESULT stomp=NOT-connected');
  exit(stompConnected ? 0 : 2);
}
