final class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kidasie-api.onrender.com',
  );

  static final Uri apiBaseUri = Uri.parse(apiBaseUrl);
}
