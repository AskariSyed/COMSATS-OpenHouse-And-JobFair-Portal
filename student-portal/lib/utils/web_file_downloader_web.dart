import 'dart:typed_data';
import 'dart:html' as html;

html.WindowBase? _previewWindow;

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

void openPreviewTab() {
  _previewWindow = html.window.open('about:blank', '_blank');
}

void openPreview(Uint8List bytes, {String mimeType = 'application/pdf'}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final previewWindow = _previewWindow;
  if (previewWindow != null) {
    previewWindow.location.href = url;
    _previewWindow = null;
    return;
  }

  html.window.location.href = url;
}
