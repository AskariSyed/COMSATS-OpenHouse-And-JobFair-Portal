import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void showGenericDialog({
  required String title,
  required Widget content,
  required Future<void> Function() onSave,
  required BuildContext context,
  bool mounted = true,
}) {
  showDialog(
    context: context,
    builder: (ctx) {
      bool isSaving = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400, // Fix width for Web
                child: content,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        try {
                          await onSave();
                          // 🔹 Refresh data after saving
                          if (mounted) {
                            await Provider.of<StudentProvider>(
                              context,
                              listen: false,
                            ).fetchProfile();
                          }
                          if (context.mounted) Navigator.pop(ctx);

                          // 🏆 SUCCESS SNACKBAR (Using top_snackbar_flutter)
                          showTopSnackBar(
                            Overlay.of(context),
                            const CustomSnackBar.success(
                              message: "Saved Successfully!",
                            ),
                          );
                        } catch (e) {
                          // 🛑 ERROR SNACKBAR (Using top_snackbar_flutter)
                          // Extract the clean message, stripping "Exception: "
                          String errorMessage = e.toString().replaceFirst(
                            'Exception: ',
                            '',
                          );

                          showTopSnackBar(
                            Overlay.of(context),
                            CustomSnackBar.error(
                              message: "Error: $errorMessage",
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}
