import 'package:flutter/foundation.dart';

class BackendConfig {
  const BackendConfig._();

  static const String _fallbackServerBaseUrl = 'https://api.jfair.tech';

  static const String configuredServerBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: '',
  );

  static String _normalizeBaseUrl(String rawBaseUrl) {
    final trimmed = rawBaseUrl.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('/')) {
      return trimmed.length > 1 && trimmed.endsWith('/')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return '';

    final normalizedPath = uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;

    final normalized = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: normalizedPath,
    );

    return normalized.toString();
  }

  static bool get _usesRelativeApiBase =>
      _resolvedServerBaseUrl.startsWith('/');

  static String get _resolvedServerBaseUrl {
    final normalizedConfigured = _normalizeBaseUrl(configuredServerBaseUrl);
    if (normalizedConfigured.isNotEmpty) return normalizedConfigured;
    return _fallbackServerBaseUrl;
  }

  static bool get isUsingFallbackServerBaseUrl {
    return _normalizeBaseUrl(configuredServerBaseUrl).isEmpty;
  }

  static bool get _isInsecureBackendOnSecurePage {
    if (!kIsWeb) return false;
    try {
      final pageUri = Uri.base;
      final backendUri = Uri.parse(_resolvedServerBaseUrl);
      return pageUri.scheme == 'https' && backendUri.scheme == 'http';
    } catch (_) {
      return false;
    }
  }

  static String get serverBaseUrl {
    if (_usesRelativeApiBase) {
      return '';
    }

    if (_isInsecureBackendOnSecurePage) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') {
        return origin;
      }
      return _resolvedServerBaseUrl;
    }
    return _resolvedServerBaseUrl;
  }

  static String get apiBaseUrl {
    if (_isInsecureBackendOnSecurePage) return '/api';
    if (_usesRelativeApiBase) return _resolvedServerBaseUrl;
    return '$serverBaseUrl/api';
  }

  static Uri apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalizedPath');
  }

  static void logResolvedConfig() {
    if (!kDebugMode) return;
    print('BACKEND_BASE_URL define: "$configuredServerBaseUrl"');
    print('Resolved serverBaseUrl: "$serverBaseUrl"');
    print('Resolved apiBaseUrl: "$apiBaseUrl"');
    if (isUsingFallbackServerBaseUrl) {
      print(
        'WARNING: BACKEND_BASE_URL missing/invalid. Using fallback: "$_fallbackServerBaseUrl"',
      );
    }
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
      if (_usesRelativeApiBase || _isInsecureBackendOnSecurePage) {
        return relativeOrAbsolutePath;
      }
      return '$serverBaseUrl$relativeOrAbsolutePath';
    }

    if (_usesRelativeApiBase || _isInsecureBackendOnSecurePage) {
      return '/$relativeOrAbsolutePath';
    }

    return '$serverBaseUrl/$relativeOrAbsolutePath';
  }
}
