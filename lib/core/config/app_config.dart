import 'dart:convert';

enum AppEnvironment { dev, uat, prod }

class AppConfig {
  const AppConfig({required this.environment, this.apiBaseUrl});
  final AppEnvironment environment;
  final Uri? apiBaseUrl;
  String get sessionScope =>
      'nf-v1-${environment.name}-${base64Url.encode(utf8.encode(apiBaseUrl?.origin ?? 'unconfigured'))}';
  factory AppConfig.fromValue(String value) => AppConfig.fromValues(value, '');
  factory AppConfig.fromValues(String value, String baseUrl) {
    final environment = AppEnvironment.values
        .where((e) => e.name == value)
        .firstOrNull;
    if (environment == null) {
      throw FormatException('Unsupported APP_ENV: $value');
    }
    if (baseUrl.isEmpty) return AppConfig(environment: environment);
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException(
        'API_BASE_URL must be an HTTPS origin without credentials, query or path.',
      );
    }
    return AppConfig(
      environment: environment,
      apiBaseUrl: Uri.parse(uri.origin),
    );
  }
}
