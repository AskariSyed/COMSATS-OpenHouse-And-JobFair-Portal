import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

Future<dynamic> showGenericDialog({
  required String title,
  required Widget content,
  required Future<dynamic> Function() onSave,
  required BuildContext context,
  bool mounted = true,
  String successMessage = "Saved Successfully!",
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool isSaving = false;
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final width = MediaQuery.of(context).size.width;
          final isWebLayout = width >= 900;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isWebLayout ? 28 : 16,
              vertical: 24,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWebLayout ? 680 : 520,
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121826) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWebLayout ? 24 : 20,
                      vertical: isWebLayout ? 20 : 16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWebLayout ? 20 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  // Content Area
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isWebLayout ? 24 : 18,
                        isWebLayout ? 22 : 16,
                        isWebLayout ? 24 : 18,
                        12,
                      ),
                      child: content,
                    ),
                  ),

                  // Action Buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      isWebLayout ? 24 : 18,
                      0,
                      isWebLayout ? 24 : 18,
                      isWebLayout ? 22 : 18,
                    ),
                    child: isWebLayout
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.grey.shade300,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setState(() => isSaving = true);
                                        try {
                                          final result = await onSave();
                                          if (result is bool &&
                                              result == false) {
                                            throw Exception(
                                              'Save operation failed.',
                                            );
                                          }

                                          final resolvedSuccessMessage =
                                              (result is String &&
                                                  result.trim().isNotEmpty)
                                              ? result
                                              : successMessage;
                                          if (mounted) {
                                            await Provider.of<StudentProvider>(
                                              context,
                                              listen: false,
                                            ).fetchProfile();
                                          }
                                          if (context.mounted)
                                            Navigator.pop(ctx);

                                          showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.success(
                                              message: resolvedSuccessMessage,
                                            ),
                                          );
                                        } catch (e) {
                                          String errorMessage = e
                                              .toString()
                                              .replaceFirst('Exception: ', '');

                                          showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.error(
                                              message: "Error: $errorMessage",
                                            ),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() => isSaving = false);
                                          }
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : const Text(
                                        "Save",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          setState(() => isSaving = true);
                                          try {
                                            final result = await onSave();
                                            if (result is bool &&
                                                result == false) {
                                              throw Exception(
                                                'Save operation failed.',
                                              );
                                            }
                                            if (mounted) {
                                              await Provider.of<
                                                    StudentProvider
                                                  >(context, listen: false)
                                                  .fetchProfile();
                                            }
                                            if (context.mounted)
                                              Navigator.pop(ctx);
                                            showTopSnackBar(
                                              Overlay.of(context),
                                              const CustomSnackBar.success(
                                                message: "Saved Successfully!",
                                              ),
                                            );
                                          } catch (e) {
                                            String errorMessage = e
                                                .toString()
                                                .replaceFirst(
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
                                            if (mounted) {
                                              setState(() => isSaving = false);
                                            }
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Text(
                                          "Save",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
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
        },
      );
    },
  );
}
