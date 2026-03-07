import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// Providers & Models
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/model/project.dart';

// Mixins
import 'package:student_job_fair_portal/mixins/contactPlaytformToString.dart';

// Screens
import 'package:student_job_fair_portal/screens/settings_screen.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/notice_board_popup.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/build_profile_content.dart';
import 'package:student_job_fair_portal/widgets/project_members_sheet.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _serverBaseUrl = "http://192.168.137.1:5158";
  bool _isInitLoading = true;
  AnimationController? _persistentSnackBarController;

  @override
  void initState() {
    super.initState();

    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    if (studentProvider.student != null) {
      _isInitLoading = false;
    } else {
      _isInitLoading = true;
    }

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
      _checkMissingDetails();
    }
  }

  Future<void> _checkMissingDetails() async {
    if (!mounted) return;
    final provider = Provider.of<StudentProvider>(context, listen: false);
    var student = provider.student;
    if (student == null) return;

    // 1. Check Name
    final fullName = student.user.fullName;
    if (fullName == null || fullName.isEmpty || fullName == "Unknown") {
      final nameCtrl = TextEditingController();
      await showGenericDialog(
        context: context,
        title: "Complete Your Profile",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please enter your full name to continue.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
          ],
        ),
        onSave: () async {
          if (nameCtrl.text.trim().isEmpty) {
            throw Exception("Full name cannot be empty.");
          }
          await provider.updateFullName(nameCtrl.text.trim());
        },
      );
      student = provider.student; // Refresh local reference
    }

    // 2. Check Phone
    if (student != null &&
        (student.user.phone == null || student.user.phone!.isEmpty)) {
      final phoneCtrl = TextEditingController();
      await showGenericDialog(
        context: context,
        title: "Add Phone Number",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please add your phone number so recruiters can contact you.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                hintText: "+92 300 1234567",
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        onSave: () async {
          if (phoneCtrl.text.trim().isEmpty) {
            throw Exception("Phone number cannot be empty.");
          }
          await provider.updatePhoneNumber(phoneCtrl.text.trim());
        },
      );
      student = provider.student;
    }

    // 3. Check CGPA
    if (student != null && (student.cgpa == 0.0)) {
      final cgpaCtrl = TextEditingController();
      await showGenericDialog(
        context: context,
        title: "Add CGPA",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please enter your current CGPA.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cgpaCtrl,
              decoration: const InputDecoration(labelText: "CGPA (e.g. 3.5)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        onSave: () async {
          final val = double.tryParse(cgpaCtrl.text);
          if (val == null || val < 0 || val > 4.0) {
            throw Exception("Please enter a valid CGPA between 0.0 and 4.0");
          }
          await provider.updateCGPA(val);
        },
      );
      student = provider.student;
    }

    // 4. Check Profile Picture
    if (student != null &&
        (student.profilePicUrl == null || student.profilePicUrl!.isEmpty)) {
      await showGenericDialog(
        context: context,
        title: "Upload Profile Picture",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "A profile picture helps recruiters recognize you. Please upload a professional photo.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Icon(Icons.account_circle, size: 80, color: Colors.grey),
          ],
        ),
        onSave: () async {
          // Trigger the existing image picker logic
          // We need to close this dialog first? No, onSave closes it after success.
          // But _onEditPicturePressed shows snackbars and might take time.
          // Let's just call it.
          await _onEditPicturePressed();
        },
      );
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

  Future<void> _onEditPicturePressed() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (mounted) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(
          message: "Uploading profile picture... Please wait.",
        ),
        persistent: true,
        onAnimationControllerInit: (controller) {
          _persistentSnackBarController = controller;
        },
      );
    }

    final provider = Provider.of<StudentProvider>(context, listen: false);
    try {
      await provider.uploadProfilePic(image);
      _persistentSnackBarController?.reverse();

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: "Profile picture updated!"),
        );
        await _loadProfileData();
      }
    } catch (e) {
      _persistentSnackBarController?.reverse();
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: "Failed to upload picture."),
        );
      }
    }
  }

  void onEditLink(dynamic link) {
    final contactLink = link as ContactLink;
    showContactLinkDialog(
      context, // Updated context reference
      link: link,
      onSaveLink: (updated) async {
        await Provider.of<StudentProvider>(
          context,
          listen: false,
        ).updateContactLink(contactLink.linkId, updated);
      },
    );
  }

  void onDeleteLink(dynamic link) async {
    final contactLink = link as ContactLink;
    await Provider.of<StudentProvider>(
      context,
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
                initialValue: selectedPlatform,
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

  Widget _buildShimmerProfile(BuildContext context) {
    // 🔹 Theme-Aware Shimmer Logic
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final cardColor = Theme.of(context).cardColor;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 20),
                Container(width: 200, height: 24, color: cardColor),
                const SizedBox(height: 10),
                Container(width: 150, height: 16, color: cardColor),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 120, height: 20, color: cardColor),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 120, height: 20, color: cardColor),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    // 🔹 Theme Colors
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final primaryColor = Theme.of(context).primaryColor;

    if (_isInitLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg, // 🔹 Theme
        body: _buildShimmerProfile(context),
      );
    }

    if (student == null) {
      return Scaffold(
        backgroundColor: scaffoldBg, // 🔹 Theme
        body: Center(
          child: Text(
            "Failed to load profile. Check connection.",
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    final String? profileImageUrl =
        (student.profilePicUrl != null && student.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : _serverBaseUrl + student.profilePicUrl!)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        if (screenWidth < 800) {
          // ==================================================================
          // MOBILE LAYOUT (Theme Updated)
          // ==================================================================
          return Scaffold(
            backgroundColor: scaffoldBg, // 🔹 Theme
            extendBody: true, // 🔹 Important for floating nav bar
            appBar: BeautifulAppBar(
              title: "My Profile",
              actions: [
                IconButton(
                  icon: const Icon(Icons.campaign_outlined),
                  onPressed: () => showNoticeBoardPopup(context),
                  tooltip: 'Notice Board',
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                // BeautifulAppBar adds logout automatically if hideLogout is false (default)
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _loadProfileData,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
            bottomNavigationBar: const BeautifulMobileNavBar(currentIndex: 1),
          );
        } else {
          // ==================================================================
          // WEB LAYOUT (Theme Updated)
          // ==================================================================
          return Scaffold(
            backgroundColor: scaffoldBg, // 🔹 Theme
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 100.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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
                                  Text(
                                    "Welcome back, ${student.user.fullName}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          // 🔹 Dynamic Color
                                          color: primaryColor,
                                        ),
                                  ),
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
                        ),
                        const SizedBox(height: 20),
                        const WebFooter(),
                      ],
                    ),
                  ),
                ),

                // 🔹 Beautiful Web Navigation Bar
                BeautifulWebNavBar(
                  currentRoute: 'Profile',
                  profileImageUrl: profileImageUrl,
                  userName: student.user.fullName ?? "User",
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
