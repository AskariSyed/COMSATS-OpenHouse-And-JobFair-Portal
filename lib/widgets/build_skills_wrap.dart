import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

Widget buildSkillsWrap(List<dynamic>? skills, BuildContext context) {
  if (skills == null || skills.isEmpty) {
    return const Center(
      child: Text("No skills listed.", style: TextStyle(color: Colors.grey)),
    );
  }

  Future<void> _confirmAndDeleteSkill(String skillToDelete) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Remove Skill?"),
          content: Text(
            "Are you sure you want to remove the skill: '$skillToDelete'?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Remove", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        bool success = await Provider.of<StudentProvider>(
          context,
          listen: false,
        ).removeSkill(skillToDelete);

        if (success) {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.success(
              message: "Skill removed successfully.",
            ),
          );
        } else {
          throw Exception("Failed to communicate with the server.");
        }
      } catch (e) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: "Failed to remove skill."),
        );
      }
    }
  }

  final isMobile = MediaQuery.of(context).size.width < 600;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Center(
    child: Wrap(
      spacing: isMobile ? 6 : 10,
      runSpacing: isMobile ? 6 : 10,
      alignment: WrapAlignment.center,
      children: skills.map<Widget>((skill) {
        final skillString = skill.toString();

        // 🔹 Chip now relies solely on the onTap gesture for deletion
        return InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          onTap: () => _confirmAndDeleteSkill(
            skillString,
          ), // Tap/Click opens confirmation
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              border: Border.all(
                color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.blue.shade900.withOpacity(0.3)
                      : Colors.blue.shade50,
                  blurRadius: isMobile ? 2 : 4,
                  offset: Offset(0, isMobile ? 1 : 2),
                ),
              ],
            ),
            // 🔹 Only the Text is displayed inside the chip
            child: Text(
              skillString,
              style: TextStyle(
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
