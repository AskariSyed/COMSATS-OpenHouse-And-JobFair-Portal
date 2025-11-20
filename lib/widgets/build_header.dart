import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/mixins/contactPlaytformToString.dart';
import 'package:student_job_fair_portal/mixins/getPlatformColor.dart';
import 'package:student_job_fair_portal/mixins/getPlatformIcon.dart';
import 'package:student_job_fair_portal/mixins/launchUrl.dart';
import 'package:student_job_fair_portal/widgets/build_social_button.dart';
import 'package:student_job_fair_portal/widgets/socialButton.dart';

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

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        // 1. Profile Picture (clickable)
        GestureDetector(
          onTap: onEditPicture,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100, width: 4),
                ),
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: Colors.grey.shade200,
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
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: onUpdateName, // 👈 Triggers name dialog
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nameMissing ? 'Click to Add Name' : student.user.fullName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: nameMissing ? Colors.red.shade700 : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 8),
                // Only show the edit icon explicitly when the name is MISSING
                Visibility(
                  visible: nameMissing,
                  child: Icon(
                    Icons.edit_note,
                    size: 24,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // 3. Department + Reg #
        Text(
          "${student.department ?? 'Department N/A'} • ${student.registrationNo}",
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),

        // 🎯 4. Phone Number Display
        if (student.user.phone != null && student.user.phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  student.user.phone,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // 5. Social Links
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            // Email Button
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
