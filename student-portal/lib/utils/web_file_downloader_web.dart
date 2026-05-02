import 'dart:typed_data';
import 'dart:html' as html;

void downloadBytes(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

void downloadFromUrl(String url, String fileName) {
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

void openPreview(Uint8List bytes, {String mimeType = 'application/pdf'}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}

