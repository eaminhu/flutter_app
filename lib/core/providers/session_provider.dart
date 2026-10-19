import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/session.dart';
import '../session/session_manager.dart';
import '../storage/session_store.dart';

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(
    store: MemorySessionStore(),
    scope: 'unconfigured-test',
  );
  ref.onDispose(() => unawaited(manager.dispose()));
  return manager;
});
final sessionStateProvider =
    NotifierProvider<SessionStateController, SessionSnapshot>(
      SessionStateController.new,
    );

class SessionStateController extends Notifier<SessionSnapshot> {
  @override
  SessionSnapshot build() {
    final manager = ref.watch(sessionManagerProvider);
    final subscription = manager.changes.listen((value) => state = value);
    ref.onDispose(() => unawaited(subscription.cancel()));
    return manager.snapshot;
  }
}
