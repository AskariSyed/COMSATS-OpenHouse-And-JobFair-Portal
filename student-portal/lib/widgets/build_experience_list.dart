import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/experience.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/mixins/dateFormatter.dart';
import 'package:student_job_fair_portal/widgets/build_empty_state.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart'; 
import 'package:student_job_fair_portal/mixins/date_picker.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

Widget buildExperienceList(List<dynamic>? experiences, BuildContext context) {
  if (experiences == null || experiences.isEmpty) {
    return buildEmptyState("No work experience added.");
  }

  void showEditExperienceDialog(Experience exp) {
    final companyCtrl = TextEditingController(text: exp.companyName);
    final roleCtrl = TextEditingController(text: exp.role);
    final locationCtrl = TextEditingController(text: exp.location ?? "");
    final descCtrl = TextEditingController(text: exp.description ?? "");

    String toDateString(DateTime? date) =>
        date?.toIso8601String().split('T').first ?? '';

    final startCtrl = TextEditingController(text: toDateString(exp.startDate));
    final endCtrl = TextEditingController(text: toDateString(exp.endDate));
    bool isCurrent = exp.isCurrent || endCtrl.text.isEmpty;

    showGenericDialog(
      context: context,
      title: "Edit Experience",
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyCtrl,
              decoration: const InputDecoration(labelText: "Company Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: "Role"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locationCtrl,
              readOnly: true,
              onTap: () => selectLocation(context, locationCtrl),
              decoration: const InputDecoration(
                labelText: "Location",
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: startCtrl,
              readOnly: true,
              onTap: () => selectDate(context, startCtrl),
              decoration: const InputDecoration(
                labelText: "Start Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: isCurrent,
                      onChanged: (value) {
                        setState(() {
                          isCurrent = value ?? false;
                          if (isCurrent) {
                            endCtrl.clear();
                          }
                        });
                      },
                      title: const Text("I am currently working here"),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: endCtrl,
                      readOnly: isCurrent,
                      onTap: isCurrent
                          ? null
                          : () => selectDate(context, endCtrl),
                      decoration: InputDecoration(
                        labelText: isCurrent
                            ? "End Date"
                            : "End Date (Optional)",
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: "Description",
                counterText: "",
                helperText: "Max 500 characters",
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      onSave: () async {
        final Map<String, dynamic> updateData = {
          "companyName": companyCtrl.text,
          "role": roleCtrl.text,
          "location": locationCtrl.text,
          "description": descCtrl.text,
          "startDate": "${startCtrl.text}T00:00:00Z",
          "endDate": isCurrent || endCtrl.text.isEmpty
              ? null
              : "${endCtrl.text}T00:00:00Z",
          "isCurrent": isCurrent,
        };

        await Provider.of<StudentProvider>(
          context,
          listen: false,
        ).updateExperience(exp.experienceId, updateData);
      },
    );
  }

  Future<bool> confirmAndDelete(int experienceId) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Experience?"),
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
                  final success = await Provider.of<StudentProvider>(
                    context,
                    listen: false,
                  ).deleteExperience(experienceId);

                  if (!success) {
                    showTopSnackBar(
                      Overlay.of(context),
                      const CustomSnackBar.error(message: "Failed to delete"),
                    );
                  } else {
                    showTopSnackBar(
                      Overlay.of(context),
                      const CustomSnackBar.success(
                        message: "Deleted successfully",
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
          ),
        ) ??
        false;
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final double availableWidth = constraints.maxWidth;
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
        children: experiences.map<Widget>((item) {
          final Experience exp = item as Experience;

          Widget cardWidget = ExperienceCard(
            experience: exp,
            onEdit: () => showEditExperienceDialog(exp),
            onDelete: () => confirmAndDelete(exp.experienceId),
          );

          if (columns == 1) {
            cardWidget = Dismissible(
              key: Key(exp.experienceId.toString()),
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
              confirmDismiss: (direction) => confirmAndDelete(exp.experienceId),
              child: cardWidget,
            );
          }

          return SizedBox(width: cardWidth, child: cardWidget);
        }).toList(),
      );
    },
  );
}

class ExperienceCard extends StatefulWidget {
  final Experience experience;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final exp = widget.experience;
    final dateRange =
        "${formatDate(exp.startDate)} - ${exp.isCurrent ? 'Present' : formatDate(exp.endDate)}";
    final hasDescription =
        exp.description != null && exp.description!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.shade900.withOpacity(0.3)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: isDark
                            ? Colors.blue.shade400
                            : Colors.blue.shade800,
                        size: isMobile ? 14 : 16,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (exp.isCurrent)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 6 : 8,
                              vertical: isMobile ? 3 : 4,
                            ),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: isMobile ? 9 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                  ],
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  exp.role,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 15,
                    height: 1.2,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(height: isMobile ? 3 : 4),
                Text(
                  exp.companyName,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (exp.location != null && exp.location!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: isDark ? Colors.grey.shade500 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          exp.location!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade500 : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _isExpanded && hasDescription
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            exp.description!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade100,
          ),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.shade50.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 60),
                Expanded(
                  child: hasDescription
                      ? InkWell(
                          onTap: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            child: Icon(icon, size: 16, color: color.withOpacity(0.8)),
          ),
        ),
      ),
    );
  }
}
