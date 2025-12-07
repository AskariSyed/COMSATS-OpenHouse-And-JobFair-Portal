import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/mixins/contactPlaytformToString.dart';
import 'package:student_job_fair_portal/mixins/getPlatformColor.dart';
import 'package:student_job_fair_portal/mixins/getPlatformIcon.dart';
import 'package:student_job_fair_portal/mixins/launchUrl.dart';
import 'package:student_job_fair_portal/widgets/build_social_button.dart';
import 'package:student_job_fair_portal/widgets/socialButton.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';

Widget buildHeader(
  BuildContext context,
  dynamic student,
  String? imageUrl,
  VoidCallback onEditPicture,
  VoidCallback onAddContactLink,
  Function(dynamic link) onEditLink,
  Function(dynamic link) onDeleteLink,
  VoidCallback onUpdateName,
) {
  final bool nameMissing =
      student.user.fullName == null || student.user.fullName.isEmpty;

  // 🔹 Theme Colors
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardColor = Theme.of(context).cardColor;
  final textColor = Theme.of(context).textTheme.bodyMedium?.color;
  final subTextColor = Theme.of(context).textTheme.bodySmall?.color;
  final borderColor = Theme.of(context).dividerColor.withOpacity(0.1);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: cardColor, // 🔹 Dynamic Background
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            isDark ? 0.3 : 0.05,
          ), // 🔹 Dynamic Shadow
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        // 1. Profile Picture
        GestureDetector(
          onTap: onEditPicture,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 4),
                ),
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cardColor,
                    width: 2,
                  ), // Border matches bg
                ),
                child: Icon(Icons.edit, color: cardColor, size: 16),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Name
        GestureDetector(
          onTap: onUpdateName,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    nameMissing ? 'Click to Add Name' : student.user.fullName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: nameMissing
                          ? Colors.red.shade700
                          : textColor, // 🔹 Dynamic Text
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (nameMissing) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.edit_note, size: 24, color: Colors.red.shade700),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // 3. Department + Reg #
        Text(
          "${student.department ?? 'Department N/A'} • ${student.registrationNo}",
          style: TextStyle(
            fontSize: 16,
            color: subTextColor,
          ), // 🔹 Dynamic Subtext
          textAlign: TextAlign.center,
        ),

        // 4. Phone Number
        const SizedBox(height: 8),
        if (student.user.phone != null && student.user.phone.isNotEmpty) ...[
          InkWell(
            onTap: () => showUpdatePhoneDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: subTextColor),
                  const SizedBox(width: 6),
                  Text(
                    student.user.phone,
                    style: TextStyle(fontSize: 15, color: subTextColor),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ] else ...[
          InkWell(
            onTap: () => showUpdatePhoneDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_call, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "Add Phone Number",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // 5. CGPA
        const SizedBox(height: 12),
        InkWell(
          onTap: () => showUpdateCGPADialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "CGPA: ${student.cgpa.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 14, color: Colors.blue.withOpacity(0.7)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 6. Social Links
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Tooltip(
              message: student.user.email,
              child: buildSocialButton(
                icon: Icons.email_outlined,
                color: Colors.redAccent,
                onTap: () => launchURL("mailto:${student.user.email}", context),
              ),
            ),
            if (student.contactLinks != null)
              for (var link in student.contactLinks)
                interactiveSocialButton(
                  context: context,
                  link: link,
                  onEditLink: onEditLink,
                  onDeleteLink: onDeleteLink,
                  onTap: () => launchURL(link.url, context),
                  child: buildSocialButton(
                    icon: getPlatformIcon(
                      contactPlatformToString(link.platform),
                    ),
                    color: getPlatformColor(
                      contactPlatformToString(link.platform),
                    ),
                    isFontAwesome: true,
                    onTap: () => launchURL(link.url, context),
                  ),
                ),
            buildSocialButton(
              icon: Icons.add_link,
              color: Theme.of(context).primaryColor,
              onTap: onAddContactLink,
            ),
          ],
        ),
      ],
    ),
  );
}
