import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/mixins/onAddPressed.dart';
import 'package:student_job_fair_portal/widgets/build_achievement_card.dart';
import 'package:student_job_fair_portal/widgets/build_certification.dart';
import 'package:student_job_fair_portal/widgets/build_education_list.dart';
import 'package:student_job_fair_portal/widgets/build_experience_list.dart';
import 'package:student_job_fair_portal/widgets/build_header.dart';
import 'package:student_job_fair_portal/widgets/build_project_list.dart';
import 'package:student_job_fair_portal/widgets/build_skills_wrap.dart';
import 'package:student_job_fair_portal/widgets/invitationList.dart';
import 'package:student_job_fair_portal/widgets/sectionHeader.dart';

Widget buildProfileContent(
  BuildContext context,
  dynamic student,
  String? profileImageUrl,
  Function(dynamic) onManageProject,
  VoidCallback onEditPicturePressed,
  VoidCallback onAddContactLink,
  Function(dynamic) onEditLink,
  Function(dynamic) onDeleteLink,
  VoidCallback onNamePressed,
  dynamic mounted,
  Key? invitationsSectionKey,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ⭐ Profile Header (Avatar, Name, Links)
      buildHeader(
        context,
        student,
        profileImageUrl,
        onEditPicturePressed,
        onAddContactLink,
        onEditLink,
        onDeleteLink,
        onNamePressed,
      ),

      const SizedBox(height: 20),

      // ⭐ Invitations (Auto-hidden if empty)
      Container(key: invitationsSectionKey, child: const InvitationsList()),

      // ⭐ Skills
      buildSectionHeader(
        'Skills',
        () => onAddPressed('Skill', context, mounted),
        context,
        mounted,
      ),
      buildSkillsWrap(student.skills, context),
      const SizedBox(height: 30),

      // ⭐ Education
      buildSectionHeader(
        'Education',
        () => onAddPressed('Education', context, mounted),
        context,
        mounted,
      ),
      buildEducationList(student.educations, context),
      const SizedBox(height: 30),
      buildSectionHeader(
        'Experience',
        () => onAddPressed('Experience', context, mounted),
        context,
        mounted,
      ),
      buildExperienceList(student.experiences, context),
      const SizedBox(height: 30),
      // ⭐ Certifications
      buildSectionHeader(
        'Certifications',
        () => onAddPressed('Certification', context, mounted),
        context,
        mounted,
      ),
      buildCertificationsList(student.certifications, context),
      const SizedBox(height: 30),

      // ⭐ Achievements
      buildSectionHeader(
        'Achievements',
        () => onAddPressed('Achievement', context, mounted),
        context,
        mounted,
      ),
      buildAchievementsList(student.achievements, context),
      const SizedBox(height: 30),

      // ⭐ Projects
      buildSectionHeader(
        'Projects',
        () => onAddPressed('Project', context, mounted),
        context,
        mounted,
      ),
      buildProjectsList(student.projects, context, onManageProject),

      const SizedBox(height: 40),
    ],
  );
}
