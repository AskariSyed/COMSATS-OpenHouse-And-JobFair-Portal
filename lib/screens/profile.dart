import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/main.dart';
import 'package:student_job_fair_portal/mixins/contactPlaytformToString.dart';
import 'package:student_job_fair_portal/model/project.dart';
import 'package:student_job_fair_portal/widgets/appbar.dart';
import 'package:student_job_fair_portal/widgets/build_bottom_navbar.dart';
import 'package:student_job_fair_portal/widgets/build_profile_content.dart';
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';
import 'package:student_job_fair_portal/widgets/project_members_sheet.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _serverBaseUrl = "http://192.168.137.1:5158";

  late List<CollapsibleItem> _sidebarItems;
  String _currentRoute = 'Profile';
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _sidebarItems = generateSidebarItems(context, setState, _currentRoute);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
    Provider.of<StudentProvider>(context, listen: false).fetchInvitations();
  }

  Future<void> _loadProfileData() async {
    await Provider.of<StudentProvider>(context, listen: false).fetchProfile();
    if (mounted) {
      setState(() {
        _isInitLoading = false;
      });
    }
  }

  // --- ACTION HANDLERS ---

  void _onUpdateNamePressed() {
    final student = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).student;
    final currentName = student?.user.fullName ?? '';
    final nameCtrl = TextEditingController(text: currentName);

    showGenericDialog(
      context: context,
      title: currentName.isEmpty ? "Add Full Name" : "Update Full Name",
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(
          labelText: "Full Name",
          border: OutlineInputBorder(),
        ),
      ),
      onSave: () async {
        final newName = nameCtrl.text.trim();
        if (newName.isEmpty) throw Exception("Full name cannot be empty.");
        await Provider.of<StudentProvider>(
          context,
          listen: false,
        ).updateFullName(newName);
      },
    );
  }

  Future<void> _onEditPicturePressed() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final provider = Provider.of<StudentProvider>(context, listen: false);
    try {
      await provider.uploadProfilePic(image);
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(message: "Profile picture updated!"),
      );
      await _loadProfileData();
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Failed to upload picture."),
      );
    }
  }

  void onEditLink(dynamic link) {
    showContactLinkDialog(
      navigatorKey.currentContext!,
      link: link,
      onSaveLink: (updated) async {
        await Provider.of<StudentProvider>(
          navigatorKey.currentContext!,
          listen: false,
        ).updateContactLink(link["id"], updated);
      },
    );
  }

  void onDeleteLink(dynamic link) async {
    await Provider.of<StudentProvider>(
      navigatorKey.currentContext!,
      listen: false,
    ).deleteContactLink(link["id"]);
  }

  void _showAddContactLinkDialog() {
    final student = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).student;
    final urlCtrl = TextEditingController();

    const List<String> allPlatforms = [
      'LinkedIn',
      'GitHub',
      'Portfolio',
      'Twitter',
      'Facebook',
      'Instagram',
      'Other',
    ];

    final existingPlatforms =
        student?.contactLinks
            .map((link) => contactPlatformToString(link.platform))
            .toSet() ??
        {};

    final availablePlatforms = allPlatforms
        .where((p) => !existingPlatforms.contains(p))
        .toList();

    if (availablePlatforms.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: "All major links added."),
      );
      return;
    }

    String selectedPlatform = availablePlatforms.first;

    showGenericDialog(
      context: context,
      title: "Add Contact Link",
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPlatform,
                items: availablePlatforms
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => setState(() => selectedPlatform = value!),
                decoration: const InputDecoration(labelText: "Platform"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: "URL"),
                keyboardType: TextInputType.url,
              ),
            ],
          );
        },
      ),
      onSave: () async {
        await Provider.of<StudentProvider>(
          context,
          listen: false,
        ).addContactLink({
          "platform": selectedPlatform,
          "url": urlCtrl.text.trim(),
        });
      },
    );
  }

  void _onManageProject(dynamic projectDynamic) {
    final Project project = projectDynamic as Project;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.group, color: Colors.indigo),
                title: const Text("View Team Members"),
                onTap: () {
                  Navigator.pop(ctx);
                  showProjectMembersSheet(
                    context,
                    project.projectId,
                    project.title,
                  );
                },
              ),
              if (project.currentStudentIsCreator) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text("Edit Project"),
                  onTap: () {
                    Navigator.pop(ctx);
                    showProjectDialog(context, project: project);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.green),
                  title: const Text("Invite Member"),
                  onTap: () {
                    Navigator.pop(ctx);
                    showInviteMemberDialog(project.projectId, context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text("Leave Project"),
                onTap: () {
                  Navigator.pop(ctx);
                  confirmLeaveProject(project.projectId, context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    if (_isInitLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (student == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load profile. Check connection.")),
      );
    }

    final String? profileImageUrl =
        (student.profilePicUrl != null && student.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : _serverBaseUrl + student.profilePicUrl!)
        : null;

    // 🚀 ROOT LAYOUT BUILDER (Handles Screen Size)
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        // --- MOBILE LAYOUT (< 800px) ---
        if (screenWidth < 800) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: buildAppBar(context, studentProvider),
            body: RefreshIndicator(
              onRefresh: _loadProfileData,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: buildProfileContent(
                      context,
                      student,
                      profileImageUrl,
                      _onManageProject,
                      _onEditPicturePressed,
                      _showAddContactLinkDialog,
                      onEditLink,
                      onDeleteLink,
                      _onUpdateNamePressed,
                      mounted,
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: buildBottomNav(context, 0),
          );
        }
        // --- WEB LAYOUT (>= 800px) ---
        else {
          return SafeArea(
            child: CollapsibleSidebar(
              isCollapsed:
                  screenWidth < 1100, // Auto-collapse on medium screens
              items: _sidebarItems,
              title: student.user.fullName ?? 'Student',
              avatarImg: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : null,
              backgroundColor: Colors.white,
              selectedIconColor: Colors.white,
              selectedIconBox: Theme.of(context).primaryColor,
              unselectedIconColor: Colors.grey.shade600,
              textStyle: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
              titleStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              toggleTitleStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              sidebarBoxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 0.01,
                  offset: const Offset(3, 3),
                ),
              ],

              // ⚠️ FIX 1: Material Wrap for InkWells
              // ⚠️ FIX 2: No hard width constraints (removes overlap)
              body: Material(
                color: Colors.grey.shade50,
                child: LayoutBuilder(
                  // ⚠️ FIX 3: Inner Builder detects sidebar squeezing
                  builder: (context, contentConstraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Align(
                        alignment: Alignment
                            .topCenter, // Keeps it centered in the remaining space
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            // Fill the SQUEEZED available width
                            // Capped at 1600 so it doesn't stretch infinitely on ultrawide
                            maxWidth: contentConstraints.maxWidth > 1600
                                ? 1600
                                : contentConstraints.maxWidth,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              buildProfileContent(
                                context,
                                student,
                                profileImageUrl,
                                _onManageProject,
                                _onEditPicturePressed,
                                _showAddContactLinkDialog,
                                onEditLink,
                                onDeleteLink,
                                _onUpdateNamePressed,
                                mounted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
