class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://quick-clix-server.onrender.com',
  );

  static Uri get uploadUri => Uri.parse('$apiBaseUrl/api/clipboard');

  static Uri get retrieveUri => Uri.parse('$apiBaseUrl/api/clipboard/retrieve');

  static Uri resolveApiPath(String path) => Uri.parse('$apiBaseUrl$path');
}
