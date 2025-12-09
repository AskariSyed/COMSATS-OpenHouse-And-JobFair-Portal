import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/achievement.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/mixins/dateFormatter.dart';
import 'package:student_job_fair_portal/mixins/date_picker.dart';
import 'package:student_job_fair_portal/widgets/build_empty_state.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

Widget buildAchievementsList(
  List<dynamic>? achievements,
  BuildContext context,
) {
  if (achievements == null || achievements.isEmpty) {
    return buildEmptyState("No achievements added.");
  }

  // 🔹 Helper: Open Edit Dialog
  void _showEditAchievementDialog(Achievement achievement) {
    final titleCtrl = TextEditingController(text: achievement.title);
    final descCtrl = TextEditingController(text: achievement.description);
    final dateCtrl = TextEditingController(
      text: achievement.dateAchieved.toIso8601String().split('T').first,
    );

    showGenericDialog(
      context: context,
      title: "Edit Achievement",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: "Achievement Title"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: "Description"),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: dateCtrl,
            readOnly: true,
            onTap: () => selectDate(context, dateCtrl),
            decoration: const InputDecoration(
              labelText: "Date Achieved",
              hintText: "YYYY-MM-DD",
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
        ],
      ),
      onSave: () async {
        await Provider.of<StudentProvider>(
          context,
          listen: false,
        ).updateAchievement(achievement.achievementId, {
          "title": titleCtrl.text,
          "description": descCtrl.text,
          "dateAchieved": "${dateCtrl.text}T00:00:00Z",
        });
      },
    );
  }

  // 🔹 Helper: Confirm Delete
  Future<bool> _confirmAndDelete(int achievementId) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text("Remove Achievement?"),
              content: const Text(
                "Are you sure you want to delete this record?",
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
                    ).deleteAchievement(achievementId);

                    if (!success) {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.error(
                          message: "Failed to delete achievement.",
                        ),
                      );
                    } else {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.success(
                          message: "Achievement deleted successfully.",
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

      // Calculate Columns based on width
      int columns = 1;
      if (availableWidth > 1350) {
        columns = 5;
      } else if (availableWidth > 1000) {
        columns = 4;
      } else if (availableWidth > 700) {
        columns = 3;
      } else if (availableWidth > 450) {
        columns = 2;
      } else {
        columns = 1;
      }

      final double spacing = 16.0;
      final double totalSpacing = (columns - 1) * spacing;
      final double cardWidth = (availableWidth - totalSpacing) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: achievements.map<Widget>((achievement) {
          final ach = achievement as Achievement;

          Widget cardWidget = AchievementCard(
            achievement: ach,
            onEdit: () => _showEditAchievementDialog(ach),
            onDelete: () => _confirmAndDelete(ach.achievementId),
          );

          // Swipe-to-delete only on mobile (1 column)
          if (columns == 1) {
            cardWidget = Dismissible(
              key: Key(ach.achievementId.toString()),
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
              confirmDismiss: (direction) =>
                  _confirmAndDelete(ach.achievementId),
              child: cardWidget,
            );
          }

          return SizedBox(width: cardWidth, child: cardWidget);
        }).toList(),
      );
    },
  );
}

// 🔹 STATEFUL CARD WIDGET
class AchievementCard extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final ach = widget.achievement;
    final hasDescription =
        ach.description != null && ach.description!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero, // Layout handles margin
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
                // --- 1. Top Row: Icon & Date ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.purple.shade900.withOpacity(0.3)
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.trophy,
                        color: isDark ? Colors.purple.shade400 : Colors.purple,
                        size: isMobile ? 14 : 16,
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
                        formatDate(ach.dateAchieved),
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

                // --- 2. Title (Full Text, No truncation) ---
                Text(
                  ach.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 15,
                    height: 1.2,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  maxLines: null, // Allow wrapping
                ),

                // --- 3. Expandable Description ---
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _isExpanded && hasDescription
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            ach.description!,
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

          // --- 4. Bottom Footer (No Overlap using Row) ---
          Container(
            height: 44, // Fixed height footer
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.shade50.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // A. Fake spacer to balance the layout (width of buttons approx)
                const SizedBox(width: 60),

                // B. Center: Expand Arrow
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

                // C. Right: Compact Action Buttons
                SizedBox(
                  width: 60, // Fixed width to prevent shifting
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildMiniButton(
                        icon: Icons.edit,
                        color: Colors.blue,
                        onTap: widget.onEdit,
                      ),
                      const SizedBox(width: 4),
                      _buildMiniButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onTap: widget.onDelete,
                      ),
                    ],
                  ),
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 16, color: color.withOpacity(0.8)),
        ),
      ),
    );
  }
}
