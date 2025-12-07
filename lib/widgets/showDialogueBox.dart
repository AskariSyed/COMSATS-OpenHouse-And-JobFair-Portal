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

// ---------------------------------------------------------------------------
// 🌍 NEW: Searchable Location Picker (World Cities)
// ---------------------------------------------------------------------------
Future<void> selectLocation(
  BuildContext context,
  TextEditingController controller,
) async {
  final String? selected = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true, // Full screen height behavior
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const CitySearchSheet(),
  );

  if (selected != null && selected.isNotEmpty) {
    controller.text = selected;
  }
}

class CitySearchSheet extends StatefulWidget {
  const CitySearchSheet({super.key});

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredLocations = [];

  // 🌏 Huge List of Major World Cities
  final List<String> _allLocations = [
    // --- Work Modes ---
    "Remote", "Onsite", "Hybrid",
    // --- Pakistan (Local Context) ---
    "Islamabad, Pakistan", "Rawalpindi, Pakistan", "Lahore, Pakistan",
    "Karachi, Pakistan", "Peshawar, Pakistan", "Quetta, Pakistan",
    "Multan, Pakistan", "Faisalabad, Pakistan", "Sialkot, Pakistan",
    "Gujranwala, Pakistan", "Hyderabad, Pakistan", "Abbottabad, Pakistan",
    "Wah Cantt, Pakistan", "Taxila, Pakistan",
    // --- North America ---
    "New York, USA", "San Francisco, USA", "Los Angeles, USA", "Chicago, USA",
    "Seattle, USA", "Austin, USA", "Boston, USA", "Toronto, Canada",
    "Vancouver, Canada", "Montreal, Canada",
    // --- Europe ---
    "London, UK", "Manchester, UK", "Berlin, Germany", "Munich, Germany",
    "Paris, France", "Amsterdam, Netherlands", "Dublin, Ireland",
    "Stockholm, Sweden", "Zurich, Switzerland", "Barcelona, Spain",
    "Madrid, Spain", "Rome, Italy", "Lisbon, Portugal",
    // --- Middle East ---
    "Dubai, UAE", "Abu Dhabi, UAE", "Riyadh, Saudi Arabia",
    "Jeddah, Saudi Arabia", "Doha, Qatar", "Kuwait City, Kuwait",
    // --- Asia Pacific ---
    "Singapore", "Tokyo, Japan", "Seoul, South Korea", "Sydney, Australia",
    "Melbourne, Australia", "Hong Kong", "Bangkok, Thailand",
    "Kuala Lumpur, Malaysia", "Mumbai, India", "Bangalore, India",
    "Delhi, India", "Beijing, China", "Shanghai, China",
  ];

  @override
  void initState() {
    super.initState();
    _filteredLocations = _allLocations;
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = _allLocations;
      } else {
        _filteredLocations = _allLocations
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle keyboard height
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 600, // Fixed height for the sheet
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Location",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 🔍 Search Bar
            TextField(
              controller: _searchController,
              autofocus: true, // Open keyboard immediately
              decoration: InputDecoration(
                hintText: "Search city (e.g. London, Dubai)...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _filterLocations,
            ),
            const SizedBox(height: 10),

            // 🏙️ List of Cities
            Expanded(
              child: ListView.separated(
                itemCount: _filteredLocations.length + 1, // +1 for custom add
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  // Option to add custom city if not found
                  if (index == _filteredLocations.length) {
                    if (_searchController.text.isNotEmpty &&
                        !_filteredLocations.contains(_searchController.text)) {
                      return ListTile(
                        leading: const Icon(
                          Icons.add_location_alt,
                          color: Colors.blue,
                        ),
                        title: Text("Use '${_searchController.text}'"),
                        subtitle: const Text("Tap to add this custom location"),
                        onTap: () =>
                            Navigator.pop(context, _searchController.text),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final city = _filteredLocations[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_city,
                      color: Colors.grey,
                    ),
                    title: Text(city),
                    onTap: () => Navigator.pop(context, city),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... [Keep the rest of your existing dialog functions below exactly as they were] ...

Future<void> showAddSkillDialog(BuildContext context, bool mounted) async {
  final bool isWeb = MediaQuery.of(context).size.width > 800;
  List<String>? result;

  if (isWeb) {
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
    result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          const SkillSelectionDialog(previouslySelectedSkills: []),
    );
  }

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

void showUpdatePhoneDialog(BuildContext context) {
  final student = Provider.of<StudentProvider>(context, listen: false).student;
  final phoneCtrl = TextEditingController(text: student?.user.phone ?? "");

  showGenericDialog(
    context: context,
    title: (student?.user.phone == null || student!.user.phone!.isEmpty)
        ? "Add Phone Number"
        : "Update Phone Number",
    content: TextField(
      controller: phoneCtrl,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: "Phone Number",
        hintText: "e.g. +92 300 1234567",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
    ),
    onSave: () async {
      if (phoneCtrl.text.trim().isEmpty) {
        throw Exception("Phone number cannot be empty.");
      }
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).updatePhoneNumber(phoneCtrl.text.trim());
    },
  );
}

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
        TextField(
          controller: startCtrl,
          readOnly: true,
          onTap: () => selectDate(context, startCtrl),
          decoration: const InputDecoration(
            labelText: "Start Date",
            hintText: "YYYY-MM-DD",
            suffixIcon: Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: endCtrl,
          readOnly: true,
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
        "startDate": "${startCtrl.text}T00:00:00Z",
        "endDate": endCtrl.text.isNotEmpty ? "${endCtrl.text}T00:00:00Z" : null,
        "isCurrent": endCtrl.text.isEmpty,
        "cgpa": double.tryParse(cgpaCtrl.text) ?? 0.0,
      });
    },
  );
}

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
      final Map<String, dynamic> data = {
        "title": titleCtrl.text,
        "issuer": issuerCtrl.text,
        "issueDate": "${dateCtrl.text}T00:00:00Z",
      };
      if (urlCtrl.text.isNotEmpty) {
        data["credentialUrl"] = urlCtrl.text;
      }
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).addCertification(data);
    },
  );
}

void showAddAchievementDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

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
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).addAchievement({
        "title": titleCtrl.text,
        "description": descCtrl.text,
        "dateAchieved": "${dateCtrl.text}T00:00:00Z",
      });
    },
  );
}

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

void showAddProjectDialog(BuildContext context) {
  final studentProvider = Provider.of<StudentProvider>(context, listen: false);
  final student = studentProvider.student;
  bool hasFyp =
      student?.projects.any((p) => p.type == ProjectType.FinalYear) ?? false;

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final demoCtrl = TextEditingController();
  final githubCtrl = TextEditingController();
  int selectedType = 0;

  showGenericDialog(
    context: context,
    title: "Add New Project",
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
        "type": selectedType,
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

void showContactLinkDialog(
  BuildContext context, {
  ContactLink? link,
  required Function(Map<String, dynamic>) onSaveLink,
}) {
  final isEditing = link != null;
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

void showUpdateCGPADialog(BuildContext context) {
  final student = Provider.of<StudentProvider>(context, listen: false).student;
  final cgpaCtrl = TextEditingController(
    text: student?.cgpa.toString() ?? "0.0",
  );

  showGenericDialog(
    context: context,
    title: "Update CGPA",
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Enter your current CGPA (0.00 - 4.00)",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: cgpaCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "CGPA",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school_outlined),
          ),
        ),
      ],
    ),
    onSave: () async {
      final val = double.tryParse(cgpaCtrl.text);
      if (val == null || val < 0 || val > 4.0) {
        throw Exception("Please enter a valid CGPA between 0.0 and 4.0");
      }
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).updateCGPA(val);
    },
  );
}

void showAddExperienceDialog(BuildContext context) {
  final companyCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();

  showGenericDialog(
    context: context,
    title: "Add Experience",
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: companyCtrl,
            decoration: const InputDecoration(labelText: "Company Name"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: roleCtrl,
            decoration: const InputDecoration(labelText: "Role / Job Title"),
          ),
          const SizedBox(height: 10),

          // 🎯 Updated Location Field to use Searchable List
          TextField(
            controller: locationCtrl,
            readOnly: true,
            onTap: () => selectLocation(context, locationCtrl),
            decoration: const InputDecoration(
              labelText: "Location",
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
          ),

          const SizedBox(height: 10),
          TextField(
            controller: startCtrl,
            readOnly: true,
            onTap: () => selectDate(context, startCtrl),
            decoration: const InputDecoration(
              labelText: "Start Date",
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: endCtrl,
            readOnly: true,
            onTap: () => selectDate(context, endCtrl),
            decoration: const InputDecoration(
              labelText: "End Date (Leave empty if Current)",
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: "Description"),
            maxLines: 3,
          ),
        ],
      ),
    ),
    onSave: () async {
      await Provider.of<StudentProvider>(context, listen: false).addExperience({
        "companyName": companyCtrl.text,
        "role": roleCtrl.text,
        "location": locationCtrl.text,
        "description": descCtrl.text,
        "startDate": "${startCtrl.text}T00:00:00Z",
        "endDate": endCtrl.text.isNotEmpty ? "${endCtrl.text}T00:00:00Z" : null,
        "isCurrent": endCtrl.text.isEmpty,
      });
    },
  );
}
