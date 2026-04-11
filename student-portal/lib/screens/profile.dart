import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// Providers & Models
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/model/project.dart';

// Mixins
import 'package:student_job_fair_portal/mixins/contactPlaytformToString.dart';

// Utils
import 'package:student_job_fair_portal/utils/image_utils.dart';

// Screens
import 'package:student_job_fair_portal/screens/settings_screen.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/notice_board_popup.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/app_animations.dart';
import 'package:student_job_fair_portal/widgets/build_profile_content.dart';
import 'package:student_job_fair_portal/widgets/project_members_sheet.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/services/cv_generator.dart';
import 'package:student_job_fair_portal/widgets/cv_editor_dialog.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ProfileScreen extends StatefulWidget {
  final bool focusProjectInvitations;

  const ProfileScreen({super.key, this.focusProjectInvitations = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _serverBaseUrl = BackendConfig.serverBaseUrl;
  bool _isInitLoading = true;
  AnimationController? _persistentSnackBarController;
  final GlobalKey _invitationsSectionKey = GlobalKey();

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
      _focusInvitationsSectionIfRequested();
    }
  }

  void _focusInvitationsSectionIfRequested() {
    if (!widget.focusProjectInvitations) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final invitationContext = _invitationsSectionKey.currentContext;
      if (invitationContext != null) {
        Scrollable.ensureVisible(
          invitationContext,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
      }
    });
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
                hintText: "e.g. 03001234567",
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
          ],
        ),
        onSave: () async {
          final phone = phoneCtrl.text.trim();
          if (!RegExp(r'^03\d{9}$').hasMatch(phone)) {
            throw Exception(
              "Phone number must be 11 digits and start with 03.",
            );
          }
          await provider.updatePhoneNumber(phone);
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
              decoration: const InputDecoration(
                labelText: "CGPA (e.g. 3.5)",
                hintText: "0.0 - 4.0",
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
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
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text("Upload Profile Picture"),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "A profile picture helps recruiters recognize you. Please upload a professional photo.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 15),
                Icon(Icons.account_circle, size: 80, color: Colors.grey),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Skip for Now"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _onEditPicturePressed();
              },
              child: const Text("Upload Picture"),
            ),
          ],
        ),
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

    if (!mounted) return;

    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.info(message: "Opening image cropper..."),
    );

    try {
      final croppedImage = await ImageUtils.cropImage(image, context);
      // Fallback to original image if crop returns null or fails (iOS Safari web issue)
      final imageToUpload = croppedImage ?? image;
      if (mounted) {
        await _validateAndUploadImage(imageToUpload);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: "Failed to crop image: ${e.toString()}",
          ),
        );
      }
    }
  }

  /// Helper method to validate and upload image
  Future<void> _validateAndUploadImage(XFile image) async {
    // ✅ Validate image
    final validation = await ImageUtils.validateImage(image);
    if (!validation.isValid) {
      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: validation.errorMessage ?? 'Invalid image.',
        ),
      );

      // ✅ If file is too large, ask for resize option
      if (validation.errorCode == 'FILE_TOO_LARGE') {
        if (!mounted) return;
        final shouldResize = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Image Too Large"),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your image size exceeded the maximum limit of 1 MB.",
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "We can automatically resize it for you:\n\n✅ Compress to fit\n✅ Maintain quality\n✅ Process instantly",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Choose Another"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Auto-Resize"),
              ),
            ],
          ),
        );

        if (shouldResize == true && mounted) {
          await _uploadWithResize(image);
        }
      }
      return;
    }

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
      final result = await provider.uploadProfilePic(image);
      _persistentSnackBarController?.reverse();

      if (mounted) {
        if (result.success) {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.success(message: "Profile picture updated!"),
          );
          await _loadProfileData();
        } else {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: result.getFormattedErrorMessage()),
          );

          // If file is too large, offer resize
          if (mounted && result.errorCode == 'FILE_TOO_LARGE') {
            final shouldResize = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text("Image Too Large"),
                content: const SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your image size exceeded the maximum limit of 1 MB.",
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "We can automatically resize it for you:\n\n✅ Compress to fit\n✅ Maintain quality\n✅ Process instantly",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text("Choose Another"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text("Auto-Resize"),
                  ),
                ],
              ),
            );

            if (shouldResize == true) {
              await _uploadWithResize(image);
            }
          }
        }
      }
    } catch (e) {
      _persistentSnackBarController?.reverse();
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "Error uploading picture: $e"),
        );
      }
    }
  }

  /// Helper method to resize and upload image
  Future<void> _uploadWithResize(XFile image) async {
    try {
      // Show progress
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.info(
            message: "⏳ Resizing image... Please wait.",
          ),
          persistent: true,
          onAnimationControllerInit: (controller) {
            _persistentSnackBarController = controller;
          },
        );
      }

      // Perform compression
      final imageBytes = await image.readAsBytes();
      final compressed = await ImageUtils.compressImage(imageBytes);

      // Upload compressed image
      final provider = Provider.of<StudentProvider>(context, listen: false);
      final result = await provider.uploadProfilePic(
        compressed,
        fileName: '${image.name}.jpg',
      );

      _persistentSnackBarController?.reverse();

      if (mounted) {
        if (result.success) {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.success(
              message: "✨ Image resized and uploaded successfully!",
            ),
          );
          await _loadProfileData();
        } else {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: result.getFormattedErrorMessage()),
          );
        }
      }
    } catch (e) {
      _persistentSnackBarController?.reverse();
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "Error resizing image: $e"),
        );
      }
    }
  }

  Future<void> _uploadGeneratedCvFlow({String? cvEmail}) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final student = studentProvider.student;
    if (student == null || !mounted) return;

    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.info(message: 'Preparing generated CV upload...'),
    );

    try {
      final pdfBytes = await CVGenerator.generatePdfBytes(
        student,
        customEmail: cvEmail,
      );
      final uploaded = await studentProvider.uploadGeneratedCv(
        pdfBytes,
        fileName:
            '${student.user.fullName?.replaceAll(' ', '_') ?? 'Student'}_CV.pdf',
      );

      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        uploaded
            ? const CustomSnackBar.success(
                message: 'Generated CV uploaded successfully.',
              )
            : const CustomSnackBar.error(
                message: 'Failed to upload generated CV.',
              ),
      );
      await _loadProfileData();
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: 'Error uploading generated CV: $e'),
      );
    }
  }

  Future<void> _pickAndUploadOwnCv() async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: 'Could not read selected PDF file.',
          ),
        );
        return;
      }

      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: 'Uploading your PDF CV...'),
      );

      final uploaded = await studentProvider.uploadGeneratedCv(
        bytes,
        fileName: file.name,
      );

      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        uploaded
            ? const CustomSnackBar.success(
                message: 'Your CV uploaded successfully.',
              )
            : const CustomSnackBar.error(message: 'Failed to upload your CV.'),
      );
      await _loadProfileData();
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: 'Error selecting/uploading PDF: $e'),
      );
    }
  }

  Widget _buildCvActionsCard(BuildContext context) {
    final student = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).student;
    final hasCv = (student?.cvUrl?.trim().isNotEmpty ?? false);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasCv ? 'Your CV is uploaded' : 'Upload Your CV',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hasCv
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: hasCv ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    hasCv ? 'Current CV: Uploaded' : 'Current CV: Not Uploaded',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasCv
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasCv
                  ? 'You can replace it with your own PDF or regenerate a fresh CV from profile data.'
                  : 'Choose to upload your own PDF CV or generate one from your profile.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickAndUploadOwnCv,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload My CV (PDF)'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final String? cvEmail = await showDialog<String>(
                      context: context,
                      builder: (ctx) => const CVEditorDialog(),
                    );
                    if (!mounted) return;
                    await _uploadGeneratedCvFlow(cvEmail: cvEmail);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate & Upload CV'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

    showContactLinkDialog(
      context,
      allowedPlatforms: availablePlatforms,
      onSaveLink: (data) async {
        await Provider.of<StudentProvider>(
          context,
          listen: false,
        ).addContactLink(data);
      },
    );
  }

  void _onManageProject(dynamic projectDynamic) {
    final Project project = projectDynamic as Project;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark
        ? const Color(0xFF3A3A4A)
        : const Color(0xFFE5E7EB);

    Widget menuTile({
      required IconData icon,
      required Color iconColor,
      required String label,
      required Color textColor,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  menuTile(
                    icon: Icons.group,
                    iconColor: Colors.indigo,
                    label: "View Team Members",
                    textColor: labelColor,
                    onTap: () {
                      Navigator.pop(ctx);
                      showProjectMembersSheet(
                        context,
                        project.projectId,
                        project.title,
                      );
                    },
                  ),
                  Divider(height: 1, color: dividerColor),
                  if (project.currentStudentIsCreator) ...[
                    menuTile(
                      icon: Icons.edit,
                      iconColor: Colors.blue,
                      label: "Edit Project",
                      textColor: labelColor,
                      onTap: () {
                        Navigator.pop(ctx);
                        showProjectDialog(context, project: project);
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    menuTile(
                      icon: Icons.person_add,
                      iconColor: Colors.green,
                      label: "Invite Member",
                      textColor: labelColor,
                      onTap: () {
                        Navigator.pop(ctx);
                        showInviteMemberDialog(project.projectId, context);
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                  ],
                  menuTile(
                    icon: Icons.exit_to_app,
                    iconColor: Colors.red,
                    label: "Leave Project",
                    textColor: Colors.red,
                    onTap: () {
                      Navigator.pop(ctx);
                      confirmLeaveProject(project.projectId, context);
                    },
                  ),
                ],
              ),
            ),
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
            body: BeautifulMobileNavBar.withSwipeNavigation(
              context: context,
              currentIndex: 1,
              child: RefreshIndicator(
                onRefresh: _loadProfileData,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: AppPageReveal(
                        child: Column(
                          children: [
                            _buildCvActionsCard(context),
                            const SizedBox(height: 12),
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
                              _invitationsSectionKey,
                            ),
                          ],
                        ),
                      ),
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
                              child: AppPageReveal(
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
                                          ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildCvActionsCard(context),
                                    const SizedBox(height: 12),
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
                                      _invitationsSectionKey,
                                    ),
                                  ],
                                ),
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
