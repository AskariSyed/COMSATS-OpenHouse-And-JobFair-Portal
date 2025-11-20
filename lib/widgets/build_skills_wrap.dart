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

  return Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: skills.map<Widget>((skill) {
        final skillString = skill.toString();

        // 🔹 Chip now relies solely on the onTap gesture for deletion
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _confirmAndDeleteSkill(
            skillString,
          ), // Tap/Click opens confirmation
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade50,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // 🔹 Only the Text is displayed inside the chip
            child: Text(
              skillString,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
