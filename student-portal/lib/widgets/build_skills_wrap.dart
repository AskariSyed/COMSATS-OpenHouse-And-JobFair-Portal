import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
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

  final isMobile = MediaQuery.of(context).size.width < 600;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Center(
    child: Wrap(
      spacing: isMobile ? 6 : 10,
      runSpacing: isMobile ? 6 : 10,
      alignment: WrapAlignment.center,
      children: skills.map<Widget>((skill) {
        return _SkillChipWidget(
          skill: skill.toString(),
          isMobile: isMobile,
          isDarkMode: isDarkMode,
        );
      }).toList(),
    ),
  );
}

class _SkillChipWidget extends StatefulWidget {
  final String skill;
  final bool isMobile;
  final bool isDarkMode;

  const _SkillChipWidget({
    required this.skill,
    required this.isMobile,
    required this.isDarkMode,
  });

  @override
  State<_SkillChipWidget> createState() => _SkillChipWidgetState();
}

class _SkillChipWidgetState extends State<_SkillChipWidget> {
  final GlobalKey<CustomPopupState> _popupKey = GlobalKey<CustomPopupState>();

  Future<void> _deleteSkill() async {
    Navigator.of(context).pop();
    try {
      final bool success = await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).removeSkill(widget.skill);
      if (success) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: "Skill removed successfully."),
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return CustomPopup(
      key: _popupKey,
      showArrow: true,
      barrierColor: Colors.black.withValues(alpha: 0.06),
      contentPadding: EdgeInsets.zero,
      contentDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D3F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      content: IntrinsicWidth(
        child: InkWell(
          onTap: _deleteSkill,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 10),
                const Text(
                  'Remove Skill',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => _popupKey.currentState?.show(),
        onSecondaryTap: () => _popupKey.currentState?.show(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 12 : 16,
            vertical: widget.isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
            border: Border.all(
              color: isDark ? Colors.blue.shade700 : Colors.blue.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.blue.shade900.withValues(alpha: 0.3)
                    : Colors.blue.shade50,
                blurRadius: widget.isMobile ? 2 : 4,
                offset: Offset(0, widget.isMobile ? 1 : 2),
              ),
            ],
          ),
          child: Text(
            widget.skill,
            style: TextStyle(
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
              fontWeight: FontWeight.w600,
              fontSize: widget.isMobile ? 12 : 14,
            ),
          ),
        ),
      ),
    );
  }
}
