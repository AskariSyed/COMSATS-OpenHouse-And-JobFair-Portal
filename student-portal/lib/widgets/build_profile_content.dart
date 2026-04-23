import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/mixins/onAddPressed.dart';
import 'package:student_job_fair_portal/model/project.dart';
import 'package:student_job_fair_portal/widgets/build_achievement_card.dart';
import 'package:student_job_fair_portal/widgets/build_certification.dart';
import 'package:student_job_fair_portal/widgets/build_education_list.dart';
import 'package:student_job_fair_portal/widgets/build_experience_list.dart';
import 'package:student_job_fair_portal/widgets/build_header.dart';
import 'package:student_job_fair_portal/widgets/build_project_list.dart';
import 'package:student_job_fair_portal/widgets/build_skills_wrap.dart';
import 'package:student_job_fair_portal/widgets/incoming_join_requests_list.dart';
import 'package:student_job_fair_portal/widgets/invitationList.dart';
import 'package:student_job_fair_portal/widgets/sectionHeader.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';

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
  final bool hasFinalYearProject = student.projects.any(
    (p) => p.type == ProjectType.FinalYear,
  );
  final List<Project> sentFypJoinRequests = student.projects
      .where(
        (p) =>
            p.type == ProjectType.FinalYear &&
            p.currentStudentStatus == ProjectInviteStatus.Pending &&
            (p.currentStudentRole ?? '').toLowerCase() == 'joinrequest',
      )
      .toList();

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
      const IncomingJoinRequestsList(),

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
      if (!hasFinalYearProject)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => showRequestJoinFypDialog(context),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text("Request To Join FYP"),
            ),
          ),
        ),
      if (sentFypJoinRequests.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sent FYP Join Requests",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...sentFypJoinRequests.map((project) {
                  final leadMember = project.partners.firstWhere(
                    (m) => m.isCreator,
                    orElse: () => project.partners.isNotEmpty
                        ? project.partners.first
                        : ProjectPartner(
                            studentId: 0,
                            name: "Team",
                            registrationNo: "",
                            role: "",
                            status: "",
                            isCreator: false,
                          ),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "- ${project.title} • Request sent to ${leadMember.name} (${leadMember.registrationNo})",
                      style: TextStyle(
                        color: Colors.blueGrey.shade800,
                        fontSize: 13,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      buildProjectsList(student.projects, context, onManageProject),

      const SizedBox(height: 40),
    ],
  );
}
