import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 600,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Select Location",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search city (e.g. London, Dubai)...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF2563EB),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: _filterLocations,
              ),
            ),
            const SizedBox(height: 16),

            // 🏙️ List of Cities
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredLocations.length + 1,
                separatorBuilder: (ctx, i) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (ctx, index) {
                  // Option to add custom city if not found
                  if (index == _filteredLocations.length) {
                    if (_searchController.text.isNotEmpty &&
                        !_filteredLocations.contains(_searchController.text)) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_location_alt_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            "Use '${_searchController.text}'",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          subtitle: const Text(
                            "Tap to add this custom location",
                            style: TextStyle(fontSize: 13),
                          ),
                          onTap: () =>
                              Navigator.pop(context, _searchController.text),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final city = _filteredLocations[index];
                  final isWorkMode = [
                    "Remote",
                    "Onsite",
                    "Hybrid",
                  ].contains(city);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isWorkMode
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isWorkMode
                            ? Icons.work_outline
                            : Icons.location_city_rounded,
                        color: isWorkMode ? Colors.green : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      city,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    onTap: () => Navigator.pop(context, city),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
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
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(
            message: "Added ${result.length} skills successfully!",
          ),
        );
        Provider.of<StudentProvider>(context, listen: false).fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "Error: $e"),
        );
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
          readOnly: true,
          onTap: () => selectDate(context, dateCtrl),
          decoration: const InputDecoration(
            labelText: "Issue Date",
            hintText: "YYYY-MM-DD",
            suffixIcon: Icon(Icons.calendar_today),
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
          readOnly: true,
          onTap: () => selectDate(context, dateCtrl),
          decoration: const InputDecoration(
            labelText: "Date Achieved",
            hintText: "YYYY-MM-DD",
            suffixIcon: Icon(Icons.calendar_today),
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
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
        UpperCaseHyphenFormatter(maxLength: 12),
      ],
      style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
      decoration: const InputDecoration(
        labelText: "Registration Number",
        hintText: "FA22-BCS-155",
        prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF2563EB)),
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
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with warning icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Leave Project?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "Are you sure you want to leave this project? If you are the creator, ownership might transfer.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      bool success = await Provider.of<StudentProvider>(
                        context,
                        listen: false,
                      ).leaveProject(projectId);

                      if (success) {
                        showTopSnackBar(
                          Overlay.of(context),
                          const CustomSnackBar.success(
                            message: "Project removed.",
                          ),
                        );
                      } else {
                        showTopSnackBar(
                          Overlay.of(context),
                          const CustomSnackBar.error(
                            message: "Failed to leave project.",
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Leave",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      data.removeWhere((key, value) => value == "");
      final provider = Provider.of<StudentProvider>(context, listen: false);
      if (isEditing) {
        await provider.updateProject(project.projectId, data);
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                "Choose an action",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Edit option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              title: const Text(
                "Edit",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                onEdit(link);
              },
            ),
            // Delete option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              title: const Text(
                "Delete",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete(link);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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

// UpperCaseHyphenFormatter for Registration Number
class UpperCaseHyphenFormatter extends TextInputFormatter {
  final int maxLength;
  UpperCaseHyphenFormatter({required this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Handle deletion - if user is deleting, preserve the operation
    if (newValue.text.length < oldValue.text.length) {
      // User is deleting
      String newText = newValue.text.toUpperCase();
      int cursorPos = newValue.selection.baseOffset;

      // If cursor is right after a hyphen that was auto-added, move it back
      if (cursorPos > 0 &&
          cursorPos < newText.length &&
          newText[cursorPos] == '-') {
        cursorPos--;
      }

      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos),
      );
    }

    // Handle addition/typing
    String text = newValue.text.toUpperCase().replaceAll('-', '');
    if (text.length > maxLength) text = text.substring(0, maxLength);

    String formatted = '';
    if (text.length >= 2) {
      formatted += text.substring(0, 2);
      if (text.length >= 4) {
        formatted += text.substring(2, 4);
      } else if (text.length > 2) {
        formatted += text.substring(2);
      }
      formatted += '-';
    } else {
      formatted = text;
    }

    if (text.length > 4) {
      if (text.length >= 7) {
        formatted += text.substring(4, 7);
      } else {
        formatted += text.substring(4);
      }
      if (text.length > 7) {
        formatted += '-';
        formatted += text.substring(7);
      }
    }

    int cursorPos = formatted.length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }
}
