import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/mixins/date_picker.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/model/project.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/mixins/contactPlaytformToString.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:student_job_fair_portal/widgets/skill_selection_dialog.dart';

String? _validateSocialUrlByPlatform(String platform, String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return 'URL is required.';

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return 'Enter a valid absolute URL (e.g. https://...).';
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return 'URL must start with http:// or https://';
  }

  final host = uri.host.toLowerCase();
  final combined = ('$host${uri.path}'.toLowerCase());

  bool containsAny(List<String> keys) =>
      keys.any((key) => combined.contains(key));

  switch (platform) {
    case 'LinkedIn':
      if (!containsAny(['linkedin.com'])) {
        return 'LinkedIn link must be from linkedin.com';
      }
      break;
    case 'GitHub':
      if (!containsAny(['github.com'])) {
        return 'GitHub link must be from github.com';
      }
      break;
    case 'Twitter':
      if (!containsAny(['twitter.com', 'x.com'])) {
        return 'Twitter link must be from twitter.com or x.com';
      }
      break;
    case 'Facebook':
      if (!containsAny(['facebook.com', 'fb.com'])) {
        return 'Facebook link must be from facebook.com';
      }
      break;
    case 'Instagram':
      if (!containsAny(['instagram.com'])) {
        return 'Instagram link must be from instagram.com';
      }
      break;
    case 'Portfolio':
    case 'Other':
      break;
  }

  return null;
}

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
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
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
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.1),
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
                            ? Colors.green.withValues(alpha: 0.1)
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
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: "Phone Number",
        hintText: "e.g. 03001234567",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
    ),
    onSave: () async {
      final phone = phoneCtrl.text.trim();
      if (!RegExp(r'^\d{11}$').hasMatch(phone)) {
        throw Exception("Phone number must be exactly 11 digits.");
      }
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).updatePhoneNumber(phone);
    },
  );
}

void showAddEducationDialog(BuildContext context) {
  final institutionCtrl = TextEditingController();
  final degreeCtrl = TextEditingController();
  final fieldCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();
  final percentageCtrl = TextEditingController();
  final marksObtainedCtrl = TextEditingController();
  final totalMarksCtrl = TextEditingController();
  String gradingType = 'CGPA';

  double? resolveCgpaValue() {
    if (gradingType == 'CGPA') {
      final cgpa = double.tryParse(percentageCtrl.text.trim());
      if (cgpa == null || cgpa < 0 || cgpa > 4.0) {
        throw Exception('CGPA must be between 0.00 and 4.00.');
      }
      return cgpa;
    }

    if (gradingType == 'Percentage') {
      final percentage = double.tryParse(percentageCtrl.text.trim());
      if (percentage == null || percentage < 0 || percentage > 100) {
        throw Exception('Percentage must be between 0 and 100.');
      }
      return null;
    }

    final obtained = double.tryParse(marksObtainedCtrl.text.trim());
    final total = double.tryParse(totalMarksCtrl.text.trim());
    if (obtained == null || total == null || total <= 0) {
      throw Exception('Provide valid obtained and total marks.');
    }
    if (obtained < 0 || obtained > total) {
      throw Exception('Obtained marks must be between 0 and total marks.');
    }
    return null;
  }

  showGenericDialog(
    context: context,
    title: "Add Education",
    content: StatefulBuilder(
      builder: (ctx, setStateDialog) => Column(
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: gradingType,
            decoration: const InputDecoration(labelText: 'Grading Type'),
            items: const [
              DropdownMenuItem(value: 'CGPA', child: Text('CGPA (0 - 4.0)')),
              DropdownMenuItem(
                value: 'Percentage',
                child: Text('Percentage (0 - 100)'),
              ),
              DropdownMenuItem(
                value: 'Marks',
                child: Text('Marks Obtained / Total Marks'),
              ),
            ],
            onChanged: (val) {
              if (val == null) return;
              setStateDialog(() => gradingType = val);
            },
          ),
          const SizedBox(height: 10),
          if (gradingType == 'Marks') ...[
            TextField(
              controller: marksObtainedCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Marks Obtained'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: totalMarksCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Total Marks'),
            ),
          ] else ...[
            TextField(
              controller: percentageCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: gradingType == 'CGPA' ? 'CGPA' : 'Percentage',
              ),
            ),
          ],
        ],
      ),
    ),
    onSave: () async {
      if (institutionCtrl.text.trim().isEmpty ||
          degreeCtrl.text.trim().isEmpty ||
          startCtrl.text.trim().isEmpty) {
        throw Exception('Institution, degree, and start date are required.');
      }

      final cgpa = resolveCgpaValue();
      final gradeValue = gradingType == 'CGPA' || gradingType == 'Percentage'
          ? double.tryParse(percentageCtrl.text.trim())
          : null;
      final marksObtained = gradingType == 'Marks'
          ? double.tryParse(marksObtainedCtrl.text.trim())
          : null;
      final totalMarks = gradingType == 'Marks'
          ? double.tryParse(totalMarksCtrl.text.trim())
          : null;

      await Provider.of<StudentProvider>(context, listen: false).addEducation({
        "institutionName": institutionCtrl.text.trim(),
        "degree": degreeCtrl.text.trim(),
        "fieldOfStudy": fieldCtrl.text.trim(),
        "startDate": "${startCtrl.text}T00:00:00Z",
        "endDate": endCtrl.text.isNotEmpty ? "${endCtrl.text}T00:00:00Z" : null,
        "isCurrent": endCtrl.text.isEmpty,
        "gradeType": gradingType,
        "gradeValue": gradeValue,
        "marksObtained": marksObtained,
        "totalMarks": totalMarks,
        "cgpa": cgpa,
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  const brandBlue = Color(0xFF2563EB);
  final fieldFill = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  final fieldBorder = isDark
      ? const Color(0xFF475569)
      : const Color(0xFFD1D9E6);
  showGenericDialog(
    context: context,
    title: "Invite Student",
    content: TextField(
      controller: regNoCtrl,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
        UpperCaseHyphenFormatter(maxLength: 12),
      ],
      style: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: "Registration Number",
        hintText: "FA22-BCS-155",
        prefixIcon: const Icon(Icons.badge_outlined, color: brandBlue),
        filled: true,
        fillColor: fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandBlue, width: 2),
        ),
      ),
    ),
    onSave: () async {
      final regNo = regNoCtrl.text.trim();
      final regNoPattern = RegExp(r'^[A-Z]{2}\d{2}-[A-Z]{3}-\d{3}$');
      if (regNo.isEmpty) {
        throw Exception("Registration number is required.");
      }
      if (!regNoPattern.hasMatch(regNo)) {
        throw Exception("Use format AA00-AAA-000 (e.g. FA22-BCS-007).");
      }
      bool success = await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).inviteStudent(projectId, regNo);

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
                      color: Colors.white.withValues(alpha: 0.2),
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
              initialValue: selectedType,
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
              initialValue: selectedType,
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
  List<String>? allowedPlatforms,
}) {
  final isEditing = link != null;
  const allPlatforms = [
    'LinkedIn',
    'GitHub',
    'Portfolio',
    'Twitter',
    'Facebook',
    'Instagram',
    'Other',
  ];
  final platforms = (allowedPlatforms != null && allowedPlatforms.isNotEmpty)
      ? allowedPlatforms
      : allPlatforms;
  String selectedPlatform;
  if (link != null) {
    selectedPlatform = contactPlatformToString(link.platform);
  } else {
    selectedPlatform = platforms.first;
  }
  if (!platforms.contains(selectedPlatform)) {
    selectedPlatform = platforms.first;
  }
  final urlCtrl = TextEditingController(text: link?.url ?? "");

  showGenericDialog(
    context: context,
    title: isEditing ? "Edit Contact Link" : "Add Contact Link",
    content: StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedPlatform,
            items: platforms
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => selectedPlatform = v);
            },
            decoration: const InputDecoration(
              labelText: 'Platform',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: urlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: "URL",
              hintText: "https://your-profile",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
    onSave: () async {
      final validationError = _validateSocialUrlByPlatform(
        selectedPlatform,
        urlCtrl.text,
      );
      if (validationError != null) {
        throw Exception(validationError);
      }

      final data = {"platform": selectedPlatform, "url": urlCtrl.text.trim()};
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
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
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
                  color: Colors.red.withValues(alpha: 0.1),
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
            decoration: const InputDecoration(
              labelText: "Description",
              counterText: "",
              helperText: "Max 500 characters",
            ),
            maxLines: 3,
            maxLength: 500,
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

// UpperCaseHyphenFormatter for strict AA00-AAA-000
class UpperCaseHyphenFormatter extends TextInputFormatter {
  final int maxLength;
  UpperCaseHyphenFormatter({required this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawInput = newValue.text.toUpperCase().replaceAll('-', '');
    final buffer = StringBuffer();

    for (final char in rawInput.split('')) {
      final index = buffer.length;
      if (index >= 10) break;

      final isLetter = RegExp(r'[A-Z]').hasMatch(char);
      final isDigit = RegExp(r'\d').hasMatch(char);

      final shouldBeLetter = index < 2 || (index >= 4 && index <= 6);
      final shouldBeDigit = (index >= 2 && index <= 3) || index >= 7;

      if ((shouldBeLetter && isLetter) || (shouldBeDigit && isDigit)) {
        buffer.write(char);
      }
    }

    final filtered = buffer.toString();
    final formatted = StringBuffer();

    for (int i = 0; i < filtered.length; i++) {
      if (i == 4 || i == 7) formatted.write('-');
      formatted.write(filtered[i]);
    }

    String result = formatted.toString();
    if (result.length > maxLength) {
      result = result.substring(0, maxLength);
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
