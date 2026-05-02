import 'dart:typed_data';

void downloadBytes(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) {
  // No-op on non-web platforms.
}

void downloadFromUrl(String url, String fileName) {
  // No-op on non-web platforms.
}

void openPreview(Uint8List bytes, {String mimeType = 'application/pdf'}) {
  // No-op on non-web platforms.
}

