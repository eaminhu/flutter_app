import '../api/errors.dart';

class AuthSession {
  const AuthSession({required this.accessToken, required this.expiresAt});
  final String accessToken;
  final DateTime? expiresAt;
}

class AccountIdentity {
  const AccountIdentity({required this.accountId});
  final String accountId;
}

enum SessionStatus {
  anonymous,
  restoring,
  authenticating,
  authenticated,
  failure,
}

class SessionSnapshot {
  const SessionSnapshot(
    this.status, {
    this.identity,
    this.error,
    this.generation = 0,
  });
  final SessionStatus status;
  final AccountIdentity? identity;
  final PlatformError? error;
  final int generation;
}
