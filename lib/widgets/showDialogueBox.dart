import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/mixins/date_picker.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/model/project.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:student_job_fair_portal/widgets/skill_selection_dialog.dart';

Future<void> showAddSkillDialog(BuildContext context, bool mounted) async {
  final bool isWeb = MediaQuery.of(context).size.width > 800;
  List<String>? result;

  if (isWeb) {
    // WEB: Large Dialog
    result = await showDialog<List<String>>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          child: const SkillSelectionDialog(previouslySelectedSkills: []),
        ),
      ),
    );
  } else {
    // MOBILE: Full Screen Bottom Sheet
    result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          const SkillSelectionDialog(previouslySelectedSkills: []),
    );
  }

  // Save Result
  if (result != null && result.isNotEmpty) {
    try {
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).addSkills(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added ${result.length} skills successfully!"),
          ),
        );
        // Refresh profile to see changes
        Provider.of<StudentProvider>(context, listen: false).fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}

// 2. Add Education
void showAddEducationDialog(BuildContext context) {
  final institutionCtrl = TextEditingController();
  final degreeCtrl = TextEditingController();
  final fieldCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();
  final cgpaCtrl = TextEditingController();

  showGenericDialog(
    context: context,
    title: "Add Education",
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: institutionCtrl,
          decoration: const InputDecoration(labelText: "Institution Name"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: degreeCtrl,
          decoration: const InputDecoration(labelText: "Degree"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: fieldCtrl,
          decoration: const InputDecoration(
            labelText: "Field of Study (e.g. CS)",
          ),
        ),
        const SizedBox(height: 10),

        // 🔹 START DATE PICKER
        TextField(
          controller: startCtrl,
          readOnly: true, // Prevents manual keyboard input
          onTap: () => selectDate(context, startCtrl),
          decoration: const InputDecoration(
            labelText: "Start Date",
            hintText: "YYYY-MM-DD",
            suffixIcon: Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 10),

        // 🔹 END DATE PICKER
        TextField(
          controller: endCtrl,
          readOnly: true, // Prevents manual keyboard input
          onTap: () => selectDate(context, endCtrl),
          decoration: const InputDecoration(
            labelText: "End Date",
            hintText: "Leave empty if current",
            suffixIcon: Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: cgpaCtrl,
          decoration: const InputDecoration(labelText: "CGPA (Optional)"),
          keyboardType: TextInputType.number,
        ),
      ],
    ),
    onSave: () async {
      await Provider.of<StudentProvider>(context, listen: false).addEducation({
        "institutionName": institutionCtrl.text,
        "degree": degreeCtrl.text,
        "fieldOfStudy": fieldCtrl.text,
        // Force UTC format for backend compatibility
        "startDate": "${startCtrl.text}T00:00:00Z",
        "endDate": endCtrl.text.isNotEmpty ? "${endCtrl.text}T00:00:00Z" : null,
        "isCurrent": endCtrl.text.isEmpty,
        "cgpa": double.tryParse(cgpaCtrl.text) ?? 0.0,
      });
    },
  );
}

// 3. Add Certification
// 3. Add Certification
void showAddCertificationDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final issuerCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final urlCtrl = TextEditingController();

  showGenericDialog(
    context: context,
    title: "Add Certification",
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: "Title"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: issuerCtrl,
          decoration: const InputDecoration(labelText: "Issuer"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: dateCtrl,
          decoration: const InputDecoration(
            labelText: "Issue Date (YYYY-MM-DD)",
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            labelText: "Credential URL (Optional)",
          ),
        ),
      ],
    ),
    onSave: () async {
      // 🔹 1. Collect required data
      final Map<String, dynamic> data = {
        "title": titleCtrl.text,
        "issuer": issuerCtrl.text,
        "issueDate": "${dateCtrl.text}T00:00:00Z",
      };

      // 🔹 2. FIX: Only add URL if the TextField is not empty
      if (urlCtrl.text.isNotEmpty) {
        data["credentialUrl"] = urlCtrl.text;
      }
      // If empty, the key is omitted, and the backend handles it as null.

      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).addCertification(data);
    },
  );
}

// 4. Add Achievement
// 4. Add Achievement
void showAddAchievementDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final dateCtrl = TextEditingController(); // YYYY-MM-DD

  showGenericDialog(
    context: context,
    title: "Add Achievement",
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
        ),
        const SizedBox(height: 10),
        TextField(
          controller: dateCtrl,
          decoration: const InputDecoration(
            labelText: "Date Achieved (YYYY-MM-DD)",
            hintText: "2024-01-15",
          ),
        ),
      ],
    ),
    onSave: () async {
      // 🔹 Call the real provider method
      await Provider.of<StudentProvider>(context, listen: false).addAchievement(
        {
          "title": titleCtrl.text,
          "description": descCtrl.text,
          // 🔹 FIX: Ensure date is sent as UTC ISO 8601 string
          "dateAchieved": "${dateCtrl.text}T00:00:00Z",
        },
      );
    },
  );
} // --- Invite Member Dialog ---

void showInviteMemberDialog(int projectId, BuildContext context) {
  final regNoCtrl = TextEditingController();
  showGenericDialog(
    context: context,
    title: "Invite Student",
    content: TextField(
      controller: regNoCtrl,
      decoration: const InputDecoration(
        labelText: "Registration No",
        hintText: "FA22-BCS-XXX",
        border: OutlineInputBorder(),
      ),
    ),
    onSave: () async {
      if (regNoCtrl.text.isEmpty) return;
      bool success = await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).inviteStudent(projectId, regNoCtrl.text.trim());

      if (!success) throw Exception("Failed to invite student.");
    },
  );
}

// --- Confirm Leave Project ---
void confirmLeaveProject(int projectId, BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Leave Project?"),
      content: const Text(
        "Are you sure you want to leave this project? If you are the creator, ownership might transfer.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            bool success = await Provider.of<StudentProvider>(
              context,
              listen: false,
            ).leaveProject(projectId);

            if (success) {
              showTopSnackBar(
                Overlay.of(context),
                const CustomSnackBar.success(message: "Project removed."),
              );
            } else {
              showTopSnackBar(
                Overlay.of(context),
                const CustomSnackBar.error(message: "Failed to leave project."),
              );
            }
          },
          child: const Text("Leave", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

// 5. Add Project (Dynamic Types)
void showAddProjectDialog(BuildContext context) {
  final studentProvider = Provider.of<StudentProvider>(context, listen: false);
  final student = studentProvider.student;

  // 1. Check if student already has an FYP
  // Assuming ProjectType.FinalYear is defined in your Project model
  bool hasFyp =
      student?.projects.any((p) => p.type == ProjectType.FinalYear) ?? false;

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final demoCtrl = TextEditingController();
  final githubCtrl = TextEditingController();

  // Default to Semester (0)
  int selectedType = 0;

  showGenericDialog(
    context: context,
    title: "Add New Project",
    // 2. Use StatefulBuilder to update Dropdown state inside the dialog
    content: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Project Type Dropdown ---
            DropdownButtonFormField<int>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: "Project Type",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text("Semester Project"),
                ),
                const DropdownMenuItem(
                  value: 1,
                  child: Text("Freelance Project"),
                ),
                // 3. Conditionally add Final Year Project option
                if (!hasFyp)
                  const DropdownMenuItem(
                    value: 2,
                    child: Text("Final Year Project"),
                  ),
                const DropdownMenuItem(value: 3, child: Text("Other")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedType = value);
                }
              },
            ),
            const SizedBox(height: 10),

            // --- Text Fields ---
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Project Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: demoCtrl,
              decoration: const InputDecoration(labelText: "Demo Video URL"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: githubCtrl,
              decoration: const InputDecoration(labelText: "GitHub URL"),
            ),
          ],
        );
      },
    ),
    onSave: () async {
      await Provider.of<StudentProvider>(context, listen: false).createProject({
        "title": titleCtrl.text,
        "description": descCtrl.text,
        "demoUrl": demoCtrl.text,
        "gitHubUrl": githubCtrl.text,
        "type": selectedType, // Send the selected integer type
      });
    },
  );
}

void showProjectDialog(BuildContext context, {Project? project}) {
  final isEditing = project != null;

  final titleCtrl = TextEditingController(text: project?.title ?? "");
  final descCtrl = TextEditingController(text: project?.description ?? "");
  final demoCtrl = TextEditingController(text: project?.demoUrl ?? "");
  final githubCtrl = TextEditingController(text: project?.gitHubUrl ?? "");

  int selectedType = project?.type.index ?? 0;

  showGenericDialog(
    context: context,
    title: isEditing ? "Edit Project" : "Add Project",
    content: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: "Project Type",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text("Semester Project")),
                DropdownMenuItem(value: 1, child: Text("Freelance Project")),
                DropdownMenuItem(value: 2, child: Text("Final Year Project")),
                DropdownMenuItem(value: 3, child: Text("Other")),
              ],
              onChanged: (v) => setState(() => selectedType = v!),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Project Title"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: "Project Description",
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: demoCtrl,
              decoration: const InputDecoration(labelText: "Demo URL"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: githubCtrl,
              decoration: const InputDecoration(labelText: "GitHub URL"),
            ),
          ],
        );
      },
    ),
    onSave: () async {
      final data = {
        "title": titleCtrl.text.trim(),
        "description": descCtrl.text.trim(),
        "demoUrl": demoCtrl.text.trim(),
        "gitHubUrl": githubCtrl.text.trim(),
        "type": selectedType,
      };

      // Remove empty or untouched URLs (this prevents backend validation errors)
      data.removeWhere((key, value) => value == null || value == "");

      final provider = Provider.of<StudentProvider>(context, listen: false);

      if (isEditing) {
        await provider.updateProject(project!.projectId, data);
      } else {
        await provider.createProject(data);
      }
    },
  );
}

// Ensure ContactLink is imported here:
// import 'package:student_job_fair_portal/model/contact_link.dart';

void showContactLinkDialog(
  BuildContext context, {
  // 🎯 FIX 1: Change parameter type to ContactLink?
  ContactLink? link,
  required Function(Map<String, dynamic>) onSaveLink,
}) {
  final isEditing = link != null;

  // 🎯 FIX 2: Access properties using dot notation
  final platformCtrl = TextEditingController(
    text: link?.platform.toString() ?? "",
  );
  final urlCtrl = TextEditingController(text: link?.url ?? "");

  showGenericDialog(
    context: context,
    title: isEditing ? "Edit Contact Link" : "Add Contact Link",
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: platformCtrl,
          decoration: const InputDecoration(
            labelText: "Platform (e.g. GitHub, LinkedIn, Portfolio)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            labelText: "URL",
            hintText: "https://your-profile",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    onSave: () async {
      final data = {
        // Send back as Map<String, dynamic> for the provider
        "platform": platformCtrl.text.trim(),
        "url": urlCtrl.text.trim(),
      };
      onSaveLink(data);
    },
  );
}

void showContactLinkActions(
  BuildContext context, {
  required ContactLink link,
  required Function(ContactLink) onEdit,
  required Function(ContactLink) onDelete,
}) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit"),
            onTap: () {
              Navigator.pop(context);
              onEdit(link);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete"),
            onTap: () {
              Navigator.pop(context);
              onDelete(link);
            },
          ),
        ],
      ),
    ),
  );
}
