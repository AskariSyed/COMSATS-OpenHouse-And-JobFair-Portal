import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/main.dart';
import 'package:student_job_fair_portal/mixins/contactPlaytformToString.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/model/project.dart';
import 'package:student_job_fair_portal/widgets/appbar.dart';
import 'package:student_job_fair_portal/widgets/build_bottom_navbar.dart';
import 'package:student_job_fair_portal/widgets/build_profile_content.dart';
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';
import 'package:student_job_fair_portal/widgets/project_members_sheet.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';

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

  // Variable to hold the SnackBar controller for manual dismissal
  AnimationController? _persistentSnackBarController;

  // Define which routes are actually ready
  final List<String> _implementedRoutes = ['Profile', 'Dashboard'];

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

  // --- UPDATED METHOD WITH PERSISTENT SNACKBAR ---
  Future<void> _onEditPicturePressed() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // 1. Show Persistent "Uploading" SnackBar
    if (mounted) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(
          message: "Uploading profile picture... Please wait.",
        ),
        persistent: true, // Keeps it visible
        onAnimationControllerInit: (controller) {
          // Capture the controller to dismiss it manually later
          _persistentSnackBarController = controller;
        },
      );
    }

    final provider = Provider.of<StudentProvider>(context, listen: false);
    try {
      await provider.uploadProfilePic(image);

      // 2. Upload finished successfully: Dismiss the "Uploading" snackbar
      _persistentSnackBarController?.reverse();

      // 3. Show Success SnackBar
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: "Profile picture updated!"),
        );
        await _loadProfileData();
      }
    } catch (e) {
      // 2. Upload failed: Dismiss the "Uploading" snackbar
      _persistentSnackBarController?.reverse();

      // 3. Show Error SnackBar
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: "Failed to upload picture."),
        );
      }
    }
  }
  // -----------------------------------------------

  void onEditLink(dynamic link) {
    final contactLink = link as ContactLink;

    showContactLinkDialog(
      navigatorKey.currentContext!,
      link: link,
      onSaveLink: (updated) async {
        await Provider.of<StudentProvider>(
          navigatorKey.currentContext!,
          listen: false,
        ).updateContactLink(contactLink.linkId, updated);
      },
    );
  }

  void onDeleteLink(dynamic link) async {
    final contactLink = link as ContactLink;

    await Provider.of<StudentProvider>(
      navigatorKey.currentContext!,
      listen: false,
    ).deleteContactLink(contactLink.linkId);
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

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    // 1. Loading State
    if (_isInitLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Error State
    if (student == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load profile. Check connection.")),
      );
    }

    // 3. Prepare Profile Image URL
    final String? profileImageUrl =
        (student.profilePicUrl != null && student.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : _serverBaseUrl + student.profilePicUrl!)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        // ====================================================================
        // MOBILE LAYOUT (< 800px)
        // ====================================================================
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
        // ====================================================================
        // WEB / DESKTOP LAYOUT (>= 800px)
        // ====================================================================
        else {
          // Regenerate sidebar items to ensure state freshness
          _sidebarItems = generateSidebarItems(
            context,
            setState,
            _currentRoute,
          );

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // A. SCROLLABLE CONTENT LAYER
                Padding(
                  padding: const EdgeInsets.only(
                    top: 80.0,
                  ), // Make room for TopBar
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 1. Main Profile Content (Centered & Constrained)
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 30,
                                horizontal: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Welcome Text
                                  Text(
                                    "Welcome back, ${student.user.fullName}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  // The actual Profile Widget
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
                        ),

                        // 2. Spacing
                        const SizedBox(height: 20),

                        // 3. WEB FOOTER (Full Width)
                        const WebFooter(),
                      ],
                    ),
                  ),
                ),

                // B. FROSTED GLASS TOP BAR LAYER
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          children: [
                            // Logo
                            Image.asset(
                              'lib/assets/StudentJobFairPortalLogo.png',
                              height: 35,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "COMSATS Job Fair",
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),

                            const Spacer(),

                            // Navigation Items
                            ..._sidebarItems.map((item) {
                              final isSelected = item.isSelected;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        if (_implementedRoutes.contains(
                                          item.text,
                                        )) {
                                          item.onPressed();
                                          setState(() {
                                            for (var i in _sidebarItems) {
                                              i.isSelected = false;
                                            }
                                            item.isSelected = true;
                                            _currentRoute = item.text;
                                          });
                                        } else {
                                          showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.info(
                                              message:
                                                  "${item.text} feature is upcoming!",
                                              backgroundColor:
                                                  Colors.orange.shade400,
                                            ),
                                          );
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.15)
                                            : Colors.transparent,
                                        foregroundColor: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey.shade700,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(item.icon, size: 20),
                                      label: Text(
                                        item.text,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                            const SizedBox(width: 20),

                            // Profile Avatar in Header
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: profileImageUrl != null
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl == null
                                  ? Text(
                                      (student.user.fullName ?? "U")[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
