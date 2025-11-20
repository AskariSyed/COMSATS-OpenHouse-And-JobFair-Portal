import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CvViewerScreen extends StatelessWidget {
  final String pdfUrl;
  const CvViewerScreen({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CV")),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
