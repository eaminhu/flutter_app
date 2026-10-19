enum PlatformErrorCode {
  backendNotConfigured,
  responseMalformed,
  unsupported,
  unexpected,
  networkUnreachable,
  requestTimeout,
  requestCancelled,
  serverError,
  authTokenExpired,
  permissionDenied,
  storageFailed,
}

class PlatformError implements Exception {
  const PlatformError(this.code, this.diagnosticMessage);
  final PlatformErrorCode code;
  final String diagnosticMessage;
  bool get retryable => switch (code) {
    PlatformErrorCode.unexpected ||
    PlatformErrorCode.networkUnreachable ||
    PlatformErrorCode.requestTimeout ||
    PlatformErrorCode.serverError => true,
    _ => false,
  };
  @override
  String toString() => 'PlatformError(${code.name}): $diagnosticMessage';
}
