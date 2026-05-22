import 'dart:typed_data';

import 'web_file_downloader_stub.dart'
    if (dart.library.html) 'web_file_downloader_web.dart'
    as impl;

class WebFileDownloader {
  const WebFileDownloader._();

  static void download(
    Uint8List bytes,
    String fileName, {
    String mimeType = 'application/octet-stream',
  }) {
    impl.downloadBytes(bytes, fileName, mimeType: mimeType);
  }

  static void downloadFromUrl(String url, String fileName) {
    impl.downloadFromUrl(url, fileName);
  }

  static void openPreviewTab() {
    impl.openPreviewTab();
  }

  static void openPreview(
    Uint8List bytes, {
    String mimeType = 'application/pdf',
  }) {
    impl.openPreview(bytes, mimeType: mimeType);
  }
}
