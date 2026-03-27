import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/education.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/mixins/dateFormatter.dart';
import 'package:student_job_fair_portal/mixins/date_picker.dart';
import 'package:student_job_fair_portal/widgets/build_empty_state.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

Widget buildEducationList(List<dynamic>? educations, BuildContext context) {
  if (educations == null || educations.isEmpty) {
    return buildEmptyState("No education history added.");
  }

  // 🔹 Helper: Open Edit Dialog
  void showEditEducationDialog(Education edu) {
    final institutionCtrl = TextEditingController(text: edu.institutionName);
    final degreeCtrl = TextEditingController(text: edu.degree);
    final normalizedGradeType = (edu.gradeType ?? '').trim().toLowerCase();
    final initialGradeType = normalizedGradeType == 'percentage'
        ? 'Percentage'
        : (normalizedGradeType == 'marks' ? 'Marks' : 'CGPA');
    String gradingType = initialGradeType;

    // Helpers to format date for text field (YYYY-MM-DD)
    String toDateString(DateTime? date) =>
        date?.toIso8601String().split('T').first ?? '';

    final startCtrl = TextEditingController(text: toDateString(edu.startDate));
    final endCtrl = TextEditingController(text: toDateString(edu.endDate));
    final double? initialGradeValue = initialGradeType == 'Percentage'
        ? (edu.gradeValue ?? ((edu.cgpa != null) ? edu.cgpa! * 25.0 : null))
        : (edu.gradeValue ?? edu.cgpa);
    final gradeValueCtrl = TextEditingController(
      text: initialGradeValue != null
          ? initialGradeValue.toStringAsFixed(2)
          : '',
    );
    final marksObtainedCtrl = TextEditingController(
      text: edu.marksObtained != null ? edu.marksObtained!.toString() : '',
    );
    final totalMarksCtrl = TextEditingController(
      text: edu.totalMarks != null ? edu.totalMarks!.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;

        double resolveCgpa() {
          if (gradingType == 'CGPA') {
            final cgpa = double.tryParse(gradeValueCtrl.text.trim());
            if (cgpa == null || cgpa < 0 || cgpa > 4.0) {
              throw Exception('CGPA must be between 0.00 and 4.00.');
            }
            return cgpa;
          }

          if (gradingType == 'Percentage') {
            final percentage = double.tryParse(gradeValueCtrl.text.trim());
            if (percentage == null || percentage < 0 || percentage > 100) {
              throw Exception('Percentage must be between 0 and 100.');
            }
            return (percentage / 25.0).clamp(0.0, 4.0);
          }

          final obtained = double.tryParse(marksObtainedCtrl.text.trim());
          final total = double.tryParse(totalMarksCtrl.text.trim());
          if (obtained == null || total == null || total <= 0) {
            throw Exception('Provide valid obtained and total marks.');
          }
          if (obtained < 0 || obtained > total) {
            throw Exception(
              'Obtained marks must be between 0 and total marks.',
            );
          }
          return ((obtained / total) * 4.0).clamp(0.0, 4.0);
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Education"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: institutionCtrl,
                        decoration: const InputDecoration(
                          labelText: "Institution Name",
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: degreeCtrl,
                        decoration: const InputDecoration(labelText: "Degree"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: startCtrl,
                        readOnly: true,
                        onTap: () => selectDate(context, startCtrl),
                        decoration: const InputDecoration(
                          labelText: "Start Date",
                          hintText: "YYYY-MM-DD",
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: endCtrl,
                        readOnly: true,
                        onTap: () => selectDate(context, endCtrl),
                        decoration: const InputDecoration(
                          labelText: "End Date",
                          hintText: "Leave empty if current",
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: gradingType,
                        decoration: const InputDecoration(
                          labelText: 'Grading Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'CGPA',
                            child: Text('CGPA (0 - 4.0)'),
                          ),
                          DropdownMenuItem(
                            value: 'Percentage',
                            child: Text('Percentage (0 - 100)'),
                          ),
                          DropdownMenuItem(
                            value: 'Marks',
                            child: Text('Marks Obtained / Total Marks'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => gradingType = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      if (gradingType == 'Marks') ...[
                        TextField(
                          controller: marksObtainedCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Marks Obtained',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: totalMarksCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Total Marks',
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: gradeValueCtrl,
                          decoration: InputDecoration(
                            labelText: gradingType == 'CGPA'
                                ? 'CGPA'
                                : 'Percentage',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    ],
                  ),
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
                            final gradeValue = gradingType == 'Marks'
                                ? null
                                : double.tryParse(gradeValueCtrl.text.trim());
                            final marksObtained = gradingType == 'Marks'
                                ? double.tryParse(marksObtainedCtrl.text.trim())
                                : null;
                            final totalMarks = gradingType == 'Marks'
                                ? double.tryParse(totalMarksCtrl.text.trim())
                                : null;

                            final Map<String, dynamic> updateData = {
                              "institutionName": institutionCtrl.text,
                              "degree": degreeCtrl.text,
                              "startDate": "${startCtrl.text}T00:00:00Z",
                              "endDate": endCtrl.text.isNotEmpty
                                  ? "${endCtrl.text}T00:00:00Z"
                                  : null,
                              "isCurrent": endCtrl.text.isEmpty,
                              "gradeType": gradingType,
                              "gradeValue": gradeValue,
                              "marksObtained": marksObtained,
                              "totalMarks": totalMarks,
                              "cgpa": resolveCgpa(),
                            };

                            final success = await Provider.of<StudentProvider>(
                              context,
                              listen: false,
                            ).updateEducation(edu.educationId, updateData);
                            if (!success) {
                              throw Exception('Failed to update education.');
                            }

                            if (ctx.mounted) Navigator.pop(ctx);

                            showTopSnackBar(
                              Overlay.of(context),
                              const CustomSnackBar.success(
                                message: "Updated Successfully!",
                              ),
                            );

                            if (context.mounted) {
                              Provider.of<StudentProvider>(
                                context,
                                listen: false,
                              ).fetchProfile();
                            }
                          } catch (e) {
                            showTopSnackBar(
                              Overlay.of(context),
                              CustomSnackBar.error(message: "Error: $e"),
                            );
                          } finally {
                            if (context.mounted) {
                              setState(() => isSaving = false);
                            }
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
                      : const Text(
                          "Update",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 Helper: Confirm Delete
  Future<bool> confirmAndDelete(int educationId) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text("Delete Education?"),
              content: const Text(
                "Are you sure you want to delete this record? This cannot be undone.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop(true);
                    bool success = await Provider.of<StudentProvider>(
                      context,
                      listen: false,
                    ).deleteEducation(educationId);

                    if (!success) {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.error(
                          message: "Failed to delete.",
                        ),
                      );
                    } else {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.success(
                          message: "Deleted successfully.",
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // 🔹 RESPONSIVE LAYOUT BUILDER
  return LayoutBuilder(
    builder: (context, constraints) {
      final double availableWidth = constraints.maxWidth;

      // Calculate Columns
      int columns = 1;
      if (availableWidth > 1350) {
        columns = 5;
      } else if (availableWidth > 1000) {
        columns = 4;
      } else if (availableWidth > 700) {
        columns = 3;
      } else if (availableWidth > 450) {
        columns = 2;
      }

      final double spacing = 16.0;
      final double totalSpacing = (columns - 1) * spacing;
      final double cardWidth = (availableWidth - totalSpacing) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: educations.map<Widget>((item) {
          final Education edu = item as Education;

          Widget cardWidget = EducationCard(
            education: edu,
            onEdit: () => showEditEducationDialog(edu),
            onDelete: () => confirmAndDelete(edu.educationId),
          );

          // Swipe-to-delete on mobile
          if (columns == 1) {
            cardWidget = Dismissible(
              key: Key(edu.educationId.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
              confirmDismiss: (direction) => confirmAndDelete(edu.educationId),
              child: cardWidget,
            );
          }

          return SizedBox(width: cardWidth, child: cardWidget);
        }).toList(),
      );
    },
  );
}

// 🔹 STATEFUL CARD WIDGET (Consistent Design)
class EducationCard extends StatefulWidget {
  final Education education;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EducationCard({
    super.key,
    required this.education,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<EducationCard> {
  String _formatNumber(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  String? _buildGradeText(Education edu) {
    final gradeType = (edu.gradeType ?? '').trim().toLowerCase();

    if (gradeType == 'percentage') {
      final value = edu.gradeValue ?? ((edu.cgpa ?? 0) * 25.0);
      if (value > 0) {
        return 'Percentage: ${_formatNumber(value)}%';
      }
    }

    if (gradeType == 'marks') {
      if (edu.marksObtained != null &&
          edu.totalMarks != null &&
          edu.totalMarks! > 0) {
        return 'Marks: ${_formatNumber(edu.marksObtained!)}/${_formatNumber(edu.totalMarks!)}';
      }
    }

    final cgpa = edu.cgpa ?? edu.gradeValue;
    if (cgpa != null && cgpa > 0) {
      return 'CGPA: ${_formatNumber(cgpa)}';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final edu = widget.education;
    final gradeText = _buildGradeText(edu);
    final dateRange =
        "${formatDate(edu.startDate)} - ${edu.isCurrent ? 'Present' : formatDate(edu.endDate)}";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Top Row: Icon & Date ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon Container
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.shade900.withValues(alpha: 0.3)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        color: isDark
                            ? Colors.orange.shade400
                            : Colors.orange.shade800,
                        size: isMobile ? 14 : 16,
                      ),
                    ),
                    // Date Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dateRange,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                          fontSize: isMobile ? 9 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 8 : 12),

                // --- 2. Degree (Title) ---
                Text(
                  edu.degree,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 15,
                    height: 1.2,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),

                SizedBox(height: isMobile ? 3 : 4),

                // --- 3. Institution (Subtitle) ---
                Text(
                  edu.institutionName,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // --- 4. Grade (Optional) ---
                if (gradeText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    gradeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade100,
          ),

          // --- 5. Bottom Footer (Actions) ---
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.shade50.withValues(alpha: 0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildMiniButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onTap: widget.onEdit,
                  tooltip: "Edit",
                ),
                const SizedBox(width: 4),
                _buildMiniButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: widget.onDelete,
                  tooltip: "Delete",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Compact Button Helper
  Widget _buildMiniButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
          ),
        ),
      ),
    );
  }
}
