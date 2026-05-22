import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/services/cv_generator.dart';
import 'package:student_job_fair_portal/widgets/cv_editor_dialog.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart';

class CVLivePreviewScreen extends StatefulWidget {
  final String? customEmail;

  const CVLivePreviewScreen({super.key, this.customEmail});

  @override
  State<CVLivePreviewScreen> createState() => _CVLivePreviewScreenState();
}

class _CVLivePreviewScreenState extends State<CVLivePreviewScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _isUploading = false;
  String? _activeCustomEmail;

  @override
  void initState() {
    super.initState();
    _activeCustomEmail = widget.customEmail;
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);
    try {
      final studentProvider = Provider.of<StudentProvider>(
        context,
        listen: false,
      );
      await studentProvider.fetchProfile();
      final updatedStudent = studentProvider.student;

      if (updatedStudent != null) {
        final bytes = await CVGenerator.generatePdfBytes(
          updatedStudent,
          customEmail: _activeCustomEmail,
        );
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Error generating CV: $e'),
        );
      }
    }
  }

  Future<void> _openEditorDialog() async {
    // Show the CV Editor Overlay
    final returnedEmail = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CVEditorDialog(),
    );
    if (returnedEmail != null &&
        returnedEmail != CVEditorDialog.discardResult) {
      _activeCustomEmail = returnedEmail;
    }
    // Once closed, re-fetch profile and re-generate PDF naturally mimicking side-by-side!
    _generatePdf();
  }

  Future<void> _uploadToServer() async {
    if (_pdfBytes == null) return;

    setState(() => _isUploading = true);

    try {
      final studentProvider = Provider.of<StudentProvider>(
        context,
        listen: false,
      );
      final student = studentProvider.student;
      if (student == null) return;

      final uploaded = await studentProvider.uploadGeneratedCv(
        _pdfBytes!,
        fileName:
            '${student.user.fullName?.replaceAll(' ', '_') ?? 'Student'}_CV.pdf',
      );

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          uploaded
              ? const CustomSnackBar.success(
                  message:
                      'CV uploaded successfully. Companies can now view it!',
                )
              : const CustomSnackBar.error(message: 'Failed to upload CV.'),
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Error uploading CV: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const BeautifulAppBar(title: "Live CV Preview", hideLogout: true),
      body: SafeArea(
        child: Column(
          children: [
            // PDF Viewer Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pdfBytes != null
                  ? SfPdfViewer.memory(_pdfBytes!)
                  : const Center(child: Text("Could not generate CV.")),
            ),

            // Interaction Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isUploading
                          ? null
                          : _openEditorDialog,
                      icon: const Icon(Icons.edit_document),
                      label: const Text("Edit Profile"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _isUploading || _pdfBytes == null
                          ? null
                          : _uploadToServer,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        _isUploading ? "Uploading..." : "Upload Final CV",
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
