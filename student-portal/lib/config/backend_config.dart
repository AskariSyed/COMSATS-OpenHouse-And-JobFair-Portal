import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class BackendConfig {
  const BackendConfig._();

  static const String configuredServerBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: '',
  );

  static bool get _isInsecureBackendOnSecurePage {
    if (!kIsWeb) return false;
    try {
      final pageUri = Uri.base;
      final backendUri = Uri.parse(configuredServerBaseUrl);
      return pageUri.scheme == 'https' && backendUri.scheme == 'http';
    } catch (_) {
      return false;
    }
  }

  static String get serverBaseUrl {
    if (_isInsecureBackendOnSecurePage) {
      final origin = html.window.location.origin ?? '';
      if (origin.isNotEmpty) {
        return origin;
      }
      return configuredServerBaseUrl;
    }
    return configuredServerBaseUrl;
  }

  static String get apiBaseUrl {
    if (_isInsecureBackendOnSecurePage) return '/api';
    return '$configuredServerBaseUrl/api';
  }

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
