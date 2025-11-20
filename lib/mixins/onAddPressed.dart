import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';

void onAddPressed(String sectionName, BuildContext context, bool mounted) {
  switch (sectionName) {
    case 'Skill':
      showAddSkillDialog(context, mounted);
      break;
    case 'Education':
      showAddEducationDialog(context);
      break;
    case 'Certification':
      showAddCertificationDialog(context);
      break;
    case 'Achievement':
      showAddAchievementDialog(context);
      break;
    case 'Project':
      showAddProjectDialog(context);
      break;
  }
}
