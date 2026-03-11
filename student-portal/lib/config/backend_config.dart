class BackendConfig {
  const BackendConfig._();

  static const String serverBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://192.168.137.1:5158',
  );

  static String get apiBaseUrl => '$serverBaseUrl/api';

  static Uri apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalizedPath');
  }

  static String absoluteUrl(String? relativeOrAbsolutePath) {
    if (relativeOrAbsolutePath == null || relativeOrAbsolutePath.isEmpty) {
      return '';
    }

    if (relativeOrAbsolutePath.startsWith('http://') ||
        relativeOrAbsolutePath.startsWith('https://')) {
      return relativeOrAbsolutePath;
    }

    if (relativeOrAbsolutePath.startsWith('/')) {
      return '$serverBaseUrl$relativeOrAbsolutePath';
    }

    return '$serverBaseUrl/$relativeOrAbsolutePath';
  }
}
