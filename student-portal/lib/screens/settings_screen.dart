import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:file_picker/file_picker.dart';

// Providers & Widgets
import 'package:student_job_fair_portal/provider/theme_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/provider/notification_provider.dart';
import 'package:student_job_fair_portal/model/student.dart';
import 'package:student_job_fair_portal/utils/password_validator.dart';
import 'package:student_job_fair_portal/screens/sigin.dart';
import 'package:student_job_fair_portal/screens/notifications_screen.dart';
import 'package:student_job_fair_portal/screens/dashboard_screen.dart';
import 'package:student_job_fair_portal/screens/job_screen.dart';
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart';
import 'package:student_job_fair_portal/widgets/notice_board_popup.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart';
import 'package:student_job_fair_portal/widgets/cv_editor_dialog.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/services/cv_generator.dart';
import 'package:student_job_fair_portal/screens/cv_live_preview.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<Map<String, String>> _developers = const [
    {
      "name": "Shumaim Zafar",
      "id": "FA22-BCS-082",
      "role": "Full Stack Developer",
    },
    {
      "name": "Hassan Askari",
      "id": "FA22-BCS-155",
      "role": "Backend & Database",
    },
    {"name": "Sulimana Huma", "id": "FA22-BCS-073", "role": "UI/UX Designer"},
  ];

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@cuiwah.edu.pk',
      query: 'subject=Job Fair Portal Support',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint("Could not launch email");
    }
  }

  Future<String?> _askCvEditPreference(
    BuildContext context, {
    required String title,
    required String message,
    required String primaryAction,
    required String secondaryAction,
  }) async {
    final shouldEdit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(primaryAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(secondaryAction),
          ),
        ],
      ),
    );

    if (shouldEdit == true && context.mounted) {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => const CVEditorDialog(),
      );
    }

    return null;
  }

  String? _resolveCvUrl(String? cvUrl) {
    if (cvUrl == null || cvUrl.isEmpty) return null;
    if (cvUrl.startsWith('http://') || cvUrl.startsWith('https://')) {
      return cvUrl;
    }
    return '${BackendConfig.serverBaseUrl}$cvUrl';
  }

  Future<void> _handleSaveProfileAsPdf(BuildContext context) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final student = studentProvider.student;
    if (student == null) return;

    final customEmail = await _askCvEditPreference(
      context,
      title: 'Download CV',
      message: 'Would you like to review and edit your CV before downloading?',
      primaryAction: 'No, Download Now',
      secondaryAction: 'Yes, Edit First',
    );

    if (!context.mounted) return;

    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.info(message: 'Generating CV...'),
    );

    try {
      await studentProvider.fetchProfile();
      final updatedStudent = studentProvider.student;
      if (updatedStudent != null) {
        await CVGenerator.generateAndSaveCV(
          updatedStudent,
          customEmail: customEmail,
        );
      }

      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'CV generated successfully!'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Error generating CV: $e'),
        );
      }
    }
  }

  Future<void> _handleShareProfile(BuildContext context) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final student = studentProvider.student;
    if (student == null) return;

    if (kIsWeb) {
      await studentProvider.fetchProfile();
      final updatedStudent = studentProvider.student;
      if (updatedStudent == null || !context.mounted) return;

      final cvUrl = _resolveCvUrl(updatedStudent.cvUrl);
      final emailBody = StringBuffer()
        ..writeln('Sharing my Job Fair profile:')
        ..writeln()
        ..writeln('Name: ${updatedStudent.user.fullName ?? 'Student'}')
        ..writeln('Registration: ${updatedStudent.registrationNo}')
        ..writeln('Department: ${updatedStudent.department}')
        ..writeln();

      if (cvUrl != null) {
        emailBody.writeln('CV: $cvUrl');
      } else {
        emailBody.writeln('CV link is not uploaded yet.');
      }

      final mailUri = Uri(
        scheme: 'mailto',
        queryParameters: {
          'subject':
              'Student Profile - ${updatedStudent.user.fullName ?? updatedStudent.registrationNo}',
          'body': emailBody.toString(),
        },
      );

      final launched = await launchUrl(mailUri);
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          launched
              ? const CustomSnackBar.success(message: 'Email composer opened.')
              : const CustomSnackBar.error(
                  message: 'Could not open email composer.',
                ),
        );
      }
      return;
    }

    final customEmail = await _askCvEditPreference(
      context,
      title: 'Share Profile',
      message: 'Would you like to review and edit your CV before sharing?',
      primaryAction: 'No, Share Now',
      secondaryAction: 'Yes, Edit First',
    );

    if (!context.mounted) return;

    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.info(message: 'Preparing CV for sharing...'),
    );

    try {
      await studentProvider.fetchProfile();
      final updatedStudent = studentProvider.student;
      if (updatedStudent != null) {
        await CVGenerator.shareCV(updatedStudent, customEmail: customEmail);
      }

      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'CV ready to share!'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Error sharing CV: $e'),
        );
      }
    }
  }

  Future<void> _handlePreviewGeneratedCv(
    BuildContext context,
    bool isMobile,
  ) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final student = studentProvider.student;
    if (student == null) return;

    if (!kIsWeb) {
      // 📱 Native handling: Launch the new Interactive Live Preview interface
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const CVLivePreviewScreen()),
      );
      return;
    }

    // 🌐 Web Handling: Just pop it into a browser tab
    final customEmail = await _askCvEditPreference(
      context,
      title: 'Preview CV',
      message: 'Would you like to review and edit your CV before previewing?',
      primaryAction: 'Preview Now',
      secondaryAction: 'Edit First',
    );

    if (!context.mounted) return;

    try {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: 'Generating CV preview...'),
      );

      await studentProvider.fetchProfile();
      final updatedStudent = studentProvider.student;
      if (updatedStudent == null || !context.mounted) return;

      final Uint8List pdfBytes = await CVGenerator.generatePdfBytes(
        updatedStudent,
        customEmail: customEmail,
      );

      await CVGenerator.previewPdfOnWeb(pdfBytes);
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(
            message: 'CV preview opened in a new browser tab.',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Error previewing CV: $e'),
        );
      }
    }
  }

  Future<void> _handleUploadGeneratedCv(BuildContext context) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final student = studentProvider.student;
    if (student == null) return;

    final customEmail = await _askCvEditPreference(
      context,
      title: 'Upload CV',
      message:
          'Would you like to review and edit your CV before uploading for companies?',
      primaryAction: 'Upload Now',
      secondaryAction: 'Edit First',
    );

    if (!context.mounted) return;

    try {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: 'Preparing CV upload...'),
      );

      await studentProvider.fetchProfile();
      final updatedStudent = studentProvider.student;
      if (updatedStudent == null) return;

      final Uint8List pdfBytes = await CVGenerator.generatePdfBytes(
        updatedStudent,
        customEmail: customEmail,
      );

      final uploaded = await studentProvider.uploadGeneratedCv(
        pdfBytes,
        fileName:
            '${updatedStudent.user.fullName?.replaceAll(' ', '_')}_CV.pdf',
      );

      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          uploaded
              ? const CustomSnackBar.success(
                  message:
                      'CV uploaded successfully. Companies can now view it.',
                )
              : const CustomSnackBar.error(message: 'Failed to upload CV.'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Error uploading CV: $e'),
        );
      }
    }
  }

  Future<void> _handleUploadOwnCv(BuildContext context) async {
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
        if (!context.mounted) return;
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: 'Could not read selected PDF file.',
          ),
        );
        return;
      }

      if (!context.mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: 'Uploading your PDF CV...'),
      );

      final uploaded = await studentProvider.uploadGeneratedCv(
        bytes,
        fileName: file.name,
      );

      if (!context.mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        uploaded
            ? const CustomSnackBar.success(
                message: 'Your CV uploaded successfully.',
              )
            : const CustomSnackBar.error(message: 'Failed to upload your CV.'),
      );
    } catch (e) {
      if (!context.mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: 'Error selecting/uploading PDF: $e'),
      );
    }
  }

  Future<void> _handleDownloadUploadedCv(BuildContext context) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );

    await studentProvider.fetchProfile();
    final currentCvUrl = _resolveCvUrl(studentProvider.student?.cvUrl);

    if (!context.mounted) return;

    if (currentCvUrl == null || currentCvUrl.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
          message: 'No uploaded CV found. Upload your CV first.',
        ),
      );
      return;
    }

    final launched = await launchUrl(
      Uri.parse(currentCvUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!context.mounted) return;
    showTopSnackBar(
      Overlay.of(context),
      launched
          ? const CustomSnackBar.success(message: 'Opening your uploaded CV...')
          : const CustomSnackBar.error(
              message: 'Could not open uploaded CV URL.',
            ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Provider.of<StudentProvider>(context, listen: false).logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildCircleActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required List<Color> colors,
    required VoidCallback onTap,
    bool isMobile = false,
  }) {
    final size = isMobile ? 46.0 : 52.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 20 : 22),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    final student = studentProvider.student;
    final String? profileImageUrl =
        (student?.profilePicUrl != null && student!.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : "${BackendConfig.serverBaseUrl}${student.profilePicUrl}")
        : null;

    // 🔹 Dynamic Colors from Theme
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final dividerColor = Theme.of(context).dividerColor;
    final iconColor =
        Theme.of(context).iconTheme.color?.withValues(alpha: 0.7) ??
        Colors.grey;

    // Mobile Layout
    if (isMobile) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const BeautifulAppBar(title: "Settings", hideLogout: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: _buildSettingsContent(
                context,
                isDark,
                cardColor,
                primaryColor,
                textColor,
                dividerColor,
                iconColor,
                isMobile,
              ),
            ),
          ),
        ),
      );
    }

    // Web Layout
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section with Job Fair Info
                _buildWebHeroSection(context, student, isDark, cardColor),

                // Main Settings Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 50,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Title for Settings
                          Text(
                            "Manage Your Account",
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Customize your preferences and manage your account",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                          ),
                          const SizedBox(height: 40),

                          // 3-Column Layout for Web
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Column 1
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildAppearanceSection(
                                      context,
                                      isDark,
                                      cardColor,
                                      primaryColor,
                                      textColor,
                                    ),
                                    const SizedBox(height: 30),
                                    _buildCVSection(
                                      context,
                                      cardColor,
                                      textColor,
                                      dividerColor,
                                      isMobile,
                                    ),
                                    const SizedBox(height: 30),
                                    _buildAccountActionsSection(
                                      context,
                                      cardColor,
                                      textColor,
                                      dividerColor,
                                      iconColor,
                                      isDark,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 25),

                              // Column 2
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildSupportSection(
                                      context,
                                      cardColor,
                                      textColor,
                                      dividerColor,
                                      iconColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 25),

                              // Column 3
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildQuickActionsSection(
                                      context,
                                      cardColor,
                                      textColor,
                                      dividerColor,
                                    ),
                                    const SizedBox(height: 30),
                                    _buildJobFairSection(
                                      context,
                                      cardColor,
                                      textColor,
                                      dividerColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const WebFooter(),
              ],
            ),
          ),
          // Web Navigation Bar
          BeautifulWebNavBar(
            currentRoute: 'Settings',
            profileImageUrl: profileImageUrl,
            userName: student?.user.fullName ?? "User",
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color primaryColor,
    Color? textColor,
    Color dividerColor,
    Color iconColor,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile) ...[
          Text(
            "Settings",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Customize your experience and manage preferences",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),
        ],
        // ----------------------------------------------------------------
        // 1. APPEARANCE SETTINGS
        // ----------------------------------------------------------------
        _buildSectionHeader(context, "Appearance"),
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      Colors.purple.shade900.withValues(alpha: 0.3),
                      cardColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.orange.shade50, cardColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 4 : 8),
            child: SwitchListTile(
              value: isDark,
              onChanged: (value) => Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).toggleTheme(value),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: isMobile ? 8 : 12,
              ),
              title: Text(
                "Dark Mode",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 16 : 18,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                isDark ? "Easy on the eyes" : "Bright and clear",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: isMobile ? 12 : 14),
              ),
              secondary: Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            Colors.purple.shade700,
                            Colors.purple.shade900,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.orange.shade300,
                            Colors.orange.shade500,
                          ],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.purple : Colors.orange)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.white,
                  size: isMobile ? 20 : 24,
                ),
              ),
              activeThumbColor: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 30),

        // ----------------------------------------------------------------
        // 2. SUPPORT & HELPLINE
        // ----------------------------------------------------------------
        _buildSectionHeader(context, "Support & Help"),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 12,
                ),
                leading: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                title: Text(
                  "Contact Helpline",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),
                subtitle: Text(
                  "support@cuiwah.edu.pk",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: isMobile ? 12 : 13),
                ),
                trailing: Icon(
                  Icons.open_in_new,
                  size: isMobile ? 18 : 20,
                  color: iconColor,
                ),
                onTap: _launchEmail,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Divider(
                  height: 1,
                  color: dividerColor.withValues(alpha: 0.2),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 12,
                ),
                leading: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.language,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                title: Text(
                  "University Website",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),
                subtitle: Text(
                  "cuiwah.edu.pk",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: isMobile ? 12 : 13),
                ),
                trailing: Icon(
                  Icons.open_in_new,
                  size: isMobile ? 18 : 20,
                  color: iconColor,
                ),
                onTap: () => launchUrl(
                  Uri.parse("https://cuiwah.edu.pk"),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Divider(
                  height: 1,
                  color: dividerColor.withValues(alpha: 0.2),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 12,
                ),
                leading: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_library_outlined,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                title: Text(
                  "Local Portal",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),
                subtitle: Text(
                  "portal.cuiwah.edu.pk",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: isMobile ? 12 : 13),
                ),
                trailing: Icon(
                  Icons.open_in_new,
                  size: isMobile ? 18 : 20,
                  color: iconColor,
                ),
                onTap: () => launchUrl(
                  Uri.parse("http://portal.cuiwah.edu.pk"),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Divider(
                  height: 1,
                  color: dividerColor.withValues(alpha: 0.2),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 12,
                ),
                leading: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                title: Text(
                  "Student Portal",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),
                subtitle: Text(
                  "cuonline.cuiwah.edu.pk",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: isMobile ? 12 : 13),
                ),
                trailing: Icon(
                  Icons.open_in_new,
                  size: isMobile ? 18 : 20,
                  color: iconColor,
                ),
                onTap: () => launchUrl(
                  Uri.parse("https://cuonline.cuiwah.edu.pk:8095/"),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Divider(
                  height: 1,
                  color: dividerColor.withValues(alpha: 0.2),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 12,
                ),
                leading: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                title: Text(
                  "RMS Portal",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),
                subtitle: Text(
                  "Review Management System",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: isMobile ? 12 : 13),
                ),
                trailing: Icon(
                  Icons.open_in_new,
                  size: isMobile ? 18 : 20,
                  color: iconColor,
                ),
                onTap: () => launchUrl(
                  Uri.parse("http://111.68.98.91/rms/student/login"),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // ----------------------------------------------------------------
        // NOTIFICATIONS
        // ----------------------------------------------------------------
        _buildSectionHeader(context, "Notifications"),
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, _) {
            final unreadCount = notificationProvider.unreadCount;

            return ListTile(
              leading: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('Notifications'),
              subtitle: Text(
                unreadCount > 0
                    ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
                    : 'View all notifications',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 16),

        // ----------------------------------------------------------------
        // NOTICE BOARD
        // ----------------------------------------------------------------
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: isDark ? cardColor : Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign, color: Colors.white),
          ),
          title: const Text('Notice Board'),
          subtitle: const Text('View important announcements'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => showNoticeBoardPopup(context),
        ),

        const SizedBox(height: 16),

        // ----------------------------------------------------------------
        // CHANGE PASSWORD
        // ----------------------------------------------------------------
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: isDark ? cardColor : Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_reset, color: Colors.white),
          ),
          title: const Text('Change Password'),
          subtitle: const Text('Update your account password'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showChangePasswordDialog(context),
        ),

        const SizedBox(height: 30),

        _buildSectionHeader(context, "Profile Actions"),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 18,
            vertical: isMobile ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.12),
            ),
          ),
          child: Wrap(
            spacing: isMobile ? 14 : 16,
            runSpacing: isMobile ? 12 : 14,
            alignment: WrapAlignment.center,
            children: [
              _buildCircleActionButton(
                context: context,
                icon: Icons.file_download_rounded,
                tooltip: 'Save Profile as PDF',
                colors: [Colors.green.shade600, Colors.green.shade800],
                isMobile: isMobile,
                onTap: () => _handleSaveProfileAsPdf(context),
              ),
              if (!kIsWeb)
                _buildCircleActionButton(
                  context: context,
                  icon: Icons.share_rounded,
                  tooltip: 'Share Profile',
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  isMobile: isMobile,
                  onTap: () => _handleShareProfile(context),
                ),
              _buildCircleActionButton(
                context: context,
                icon: Icons.preview_rounded,
                tooltip: 'Preview Generated CV',
                colors: [Colors.orange.shade600, Colors.orange.shade800],
                isMobile: isMobile,
                onTap: () => _handlePreviewGeneratedCv(context, isMobile),
              ),
              _buildCircleActionButton(
                context: context,
                icon: Icons.cloud_upload_rounded,
                tooltip: 'Upload My PDF CV',
                colors: [Colors.teal.shade600, Colors.teal.shade800],
                isMobile: isMobile,
                onTap: () => _handleUploadOwnCv(context),
              ),
              _buildCircleActionButton(
                context: context,
                icon: Icons.logout_rounded,
                tooltip: 'Logout',
                colors: [Colors.red.shade600, Colors.red.shade800],
                isMobile: isMobile,
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
        ),

        // ----------------------------------------------------------------
        // 3. DEVELOPER CREDITS (Mobile Only)
        // ----------------------------------------------------------------
        if (isMobile) ...[
          const SizedBox(height: 30),
          _buildSectionHeader(context, "Meet the Team"),
          Column(
            children: _developers
                .map(
                  (dev) => _buildDeveloperCard(
                    context,
                    dev,
                    isDark,
                    cardColor,
                    primaryColor,
                    textColor,
                    dividerColor,
                    isMobile,
                  ),
                )
                .toList(),
          ),
        ],
        SizedBox(height: isMobile ? 20 : 40),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    bool isSubmitting = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Password strength helpers
    int getStrength(String p) {
      int score = 0;
      if (p.length >= 8) score++;
      if (p.contains(RegExp(r'[A-Z]'))) score++;
      if (p.contains(RegExp(r'[0-9]'))) score++;
      if (p.contains(RegExp(r'[!@#\$&*~^%]'))) score++;
      return score; // 0-4
    }

    Color strengthColor(int s) {
      if (s <= 1) return Colors.red.shade400;
      if (s == 2) return Colors.orange.shade400;
      if (s == 3) return Colors.yellow.shade700;
      return Colors.green.shade500;
    }

    String strengthLabel(int s) {
      if (s <= 1) return 'Weak';
      if (s == 2) return 'Fair';
      if (s == 3) return 'Good';
      return 'Strong';
    }

    InputDecoration fieldDecoration(
      String label,
      IconData icon,
      bool show,
      VoidCallback toggle,
    ) {
      return InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        suffixIcon: IconButton(
          splashRadius: 18,
          icon: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: Colors.grey.shade500,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final newPass = newPasswordController.text;
          final strength = getStrength(newPass);
          final confirmPass = confirmPasswordController.text;
          final passwordsMatch =
              confirmPass.isNotEmpty && newPass == confirmPass;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Gradient Header ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Keep your account secure',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                    ),

                    // ── Body ─────────────────────────────────────────
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current password
                            TextField(
                              controller: currentPasswordController,
                              obscureText: !showCurrentPassword,
                              decoration: fieldDecoration(
                                'Current Password',
                                Icons.lock_outline_rounded,
                                showCurrentPassword,
                                () => setState(
                                  () => showCurrentPassword =
                                      !showCurrentPassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // New password
                            TextField(
                              controller: newPasswordController,
                              obscureText: !showNewPassword,
                              onChanged: (_) => setState(() {}),
                              decoration: fieldDecoration(
                                'New Password',
                                Icons.lock_rounded,
                                showNewPassword,
                                () => setState(
                                  () => showNewPassword = !showNewPassword,
                                ),
                              ),
                            ),

                            // Strength indicator
                            if (newPass.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ...List.generate(4, (i) {
                                    return Expanded(
                                      child: Container(
                                        height: 4,
                                        margin: EdgeInsets.only(
                                          right: i < 3 ? 4 : 0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: i < strength
                                              ? strengthColor(strength)
                                              : (isDark
                                                    ? Colors.white12
                                                    : Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 10),
                                  Text(
                                    strengthLabel(strength),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: strengthColor(strength),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Confirm password
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: !showConfirmPassword,
                              onChanged: (_) => setState(() {}),
                              decoration:
                                  fieldDecoration(
                                    'Confirm New Password',
                                    Icons.lock_clock_outlined,
                                    showConfirmPassword,
                                    () => setState(
                                      () => showConfirmPassword =
                                          !showConfirmPassword,
                                    ),
                                  ).copyWith(
                                    suffixIcon: confirmPass.isEmpty
                                        ? IconButton(
                                            splashRadius: 18,
                                            icon: Icon(
                                              showConfirmPassword
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              size: 20,
                                              color: Colors.grey.shade500,
                                            ),
                                            onPressed: () => setState(
                                              () => showConfirmPassword =
                                                  !showConfirmPassword,
                                            ),
                                          )
                                        : Icon(
                                            passwordsMatch
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                            size: 20,
                                            color: passwordsMatch
                                                ? Colors.green.shade500
                                                : Colors.red.shade400,
                                          ),
                                  ),
                            ),

                            // Hint text
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.blue.shade900.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.blue.shade700.withValues(
                                          alpha: 0.4,
                                        )
                                      : Colors.blue.shade100,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Use 8+ characters with uppercase, numbers & symbols for a strong password.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? Colors.blue.shade200
                                            : Colors.blue.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // ── Footer Buttons ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final current = currentPasswordController
                                          .text
                                          .trim();
                                      final newP = newPasswordController.text
                                          .trim();
                                      final confirm = confirmPasswordController
                                          .text
                                          .trim();

                                      if (current.isEmpty ||
                                          newP.isEmpty ||
                                          confirm.isEmpty) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          const CustomSnackBar.error(
                                            message: 'All fields are required',
                                          ),
                                        );
                                        return;
                                      }

                                      final passwordError =
                                          PasswordValidator.validate(newP);
                                      if (passwordError != null) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            message: passwordError,
                                          ),
                                        );
                                        return;
                                      }

                                      if (newP != confirm) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          const CustomSnackBar.error(
                                            message:
                                                'New passwords do not match',
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => isSubmitting = true);
                                      try {
                                        await Provider.of<StudentProvider>(
                                          context,
                                          listen: false,
                                        ).changePassword(
                                          current,
                                          newP,
                                          confirm,
                                        );

                                        if (context.mounted) {
                                          Navigator.of(ctx).pop();
                                          showTopSnackBar(
                                            Overlay.of(context),
                                            const CustomSnackBar.success(
                                              message:
                                                  'Password changed successfully!',
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setState(() => isSubmitting = false);
                                        if (context.mounted) {
                                          String msg = e.toString();
                                          if (msg.startsWith('Exception: ')) {
                                            msg = msg.substring(11);
                                          }
                                          showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.error(message: msg),
                                          );
                                        }
                                      }
                                    },
                              icon: isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: Text(
                                isSubmitting ? 'Saving…' : 'Change Password',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16, left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: isMobile ? 16 : 20,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(
    BuildContext context,
    Map<String, String> dev,
    bool isDark,
    Color cardColor,
    Color primaryColor,
    Color? textColor,
    Color dividerColor,
    bool isMobile,
  ) {
    final gradientColors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.pink,
      Colors.teal,
    ];
    final colorIndex = dev['name']!.hashCode.abs() % gradientColors.length;
    final devColor = gradientColors[colorIndex];

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 0),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isMobile ? 50 : 60,
              height: isMobile ? 50 : 60,
              decoration: BoxDecoration(
                color: devColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: devColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  dev['name']![0],
                  style: TextStyle(
                    color: devColor.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 22 : 26,
                  ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 14 : 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dev['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 15 : 17,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dev['role']!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: devColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: devColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dev['id']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: isMobile ? 10 : 11,
                        color: devColor,
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
    );
  }

  // Helper method to build appearance section for web
  Widget _buildAppearanceSection(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color primaryColor,
    Color? textColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  Colors.purple.shade900.withValues(alpha: 0.3),
                  cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.orange.shade50, cardColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Appearance"),
            const SizedBox(height: 16),
            SwitchListTile(
              value: isDark,
              onChanged: (value) => Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).toggleTheme(value),
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Dark Mode",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(isDark ? "Enabled" : "Disabled"),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build CV section for web
  Widget _buildCVSection(
    BuildContext context,
    Color cardColor,
    Color? textColor,
    Color dividerColor,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
        border: Border.all(color: dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "CV Management"),
            const SizedBox(height: 4),
            _buildQuickActionItem(
              context,
              Icons.edit_document,
              "Generate CV",
              "Auto-build CV from your profile",
              Colors.blue,
              onTap: () => _handleUploadGeneratedCv(context),
            ),
            Divider(color: dividerColor, height: 20),
            _buildQuickActionItem(
              context,
              Icons.cloud_upload_outlined,
              "Upload CV",
              "Upload your own PDF",
              Colors.teal,
              onTap: () => _handleUploadOwnCv(context),
            ),
            Divider(color: dividerColor, height: 20),
            _buildQuickActionItem(
              context,
              Icons.preview_outlined,
              "Preview CV",
              "View your generated CV",
              Colors.orange,
              onTap: () => _handlePreviewGeneratedCv(context, false),
            ),
            Divider(color: dividerColor, height: 20),
            _buildQuickActionItem(
              context,
              Icons.download_outlined,
              "Download CV",
              "Save CV to your device",
              Colors.purple,
              onTap: () => _handleDownloadUploadedCv(context),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build support section for web
  Widget _buildSupportSection(
    BuildContext context,
    Color cardColor,
    Color? textColor,
    Color dividerColor,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
        border: Border.all(color: dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Support & Help"),
            const SizedBox(height: 16),
            _buildSupportLinkItem(
              context,
              iconColor,
              dividerColor,
              Icons.email_outlined,
              "Email Support",
              "Reach our team directly",
              Icons.arrow_forward_ios,
              onTap: () => _launchEmail(),
            ),
            Divider(color: dividerColor, height: 16),
            _buildSupportLinkItem(
              context,
              iconColor,
              dividerColor,
              Icons.language_outlined,
              "Official Website",
              "cuiwah.edu.pk",
              Icons.open_in_new,
              onTap: () => launchUrl(
                Uri.parse("https://cuiwah.edu.pk"),
                mode: LaunchMode.externalApplication,
              ),
            ),
            Divider(color: dividerColor, height: 16),
            _buildSupportLinkItem(
              context,
              iconColor,
              dividerColor,
              Icons.school_outlined,
              "COMSATS Main",
              "comsats.edu.pk",
              Icons.open_in_new,
              onTap: () => launchUrl(
                Uri.parse("https://comsats.edu.pk"),
                mode: LaunchMode.externalApplication,
              ),
            ),
            Divider(color: dividerColor, height: 16),
            _buildSupportLinkItem(
              context,
              iconColor,
              dividerColor,
              Icons.web_outlined,
              "Local Portal",
              "portal.cuiwah.edu.pk",
              Icons.open_in_new,
              onTap: () => launchUrl(
                Uri.parse("https://portal.cuiwah.edu.pk/"),
                mode: LaunchMode.externalApplication,
              ),
            ),
            Divider(color: dividerColor, height: 16),
            _buildSupportLinkItem(
              context,
              iconColor,
              dividerColor,
              Icons.account_circle_outlined,
              "Student Portal",
              "cuonline.cuiwah.edu.pk",
              Icons.open_in_new,
              onTap: () => launchUrl(
                Uri.parse("https://cuonline.cuiwah.edu.pk:8095/"),
                mode: LaunchMode.externalApplication,
              ),
            ),
            Divider(color: dividerColor, height: 16),
            _buildSupportLinkItem(
              context,
              iconColor,
              dividerColor,
              Icons.terminal_outlined,
              "RMS Console",
              "FYP Schedule",
              Icons.open_in_new,
              onTap: () => launchUrl(
                Uri.parse(
                  "http://111.68.98.91/rms/student-console/fyp-schedule",
                ),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Account Actions section for web (Change Password + Logout)
  Widget _buildAccountActionsSection(
    BuildContext context,
    Color cardColor,
    Color? textColor,
    Color dividerColor,
    Color iconColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Account"),
            const SizedBox(height: 4),

            // Change Password
            _buildQuickActionItem(
              context,
              Icons.lock_reset_rounded,
              "Change Password",
              "Update your account password",
              Colors.orange,
              onTap: () => _showChangePasswordDialog(context),
            ),

            Divider(color: dividerColor, height: 20),

            // Logout
            _buildQuickActionItem(
              context,
              Icons.logout_rounded,
              "Logout",
              "Sign out of your account",
              Colors.red,
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  // Hero Section with Job Fair Information
  Widget _buildWebHeroSection(
    BuildContext context,
    Student? student,
    bool isDark,
    Color cardColor,
  ) {
    final dashboardProvider = Provider.of<StudentProvider>(context);
    final marketOverview = dashboardProvider.dashboardData?.marketOverview;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.blue.shade900, Colors.purple.shade900]
              : [Colors.blue.shade50, Colors.purple.shade50],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Text
                Text(
                  "Welcome, ${student?.user.fullName ?? 'Student'}",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Manage your profile and job fair registrations",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 40),

                // Job Fair Info Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildJobFairInfoCard(
                        context,
                        "Registered Job Fair",
                        marketOverview?.activeFairSemester ?? "N/A",
                        "📋",
                        isDark,
                        cardColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildJobFairInfoCard(
                        context,
                        "Participating Companies",
                        marketOverview != null
                            ? "${marketOverview.totalCompanies}"
                            : "—",
                        "🏢",
                        isDark,
                        cardColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildJobFairInfoCard(
                        context,
                        "Available Positions",
                        marketOverview != null
                            ? "${marketOverview.totalJobs}"
                            : "—",
                        "💼",
                        isDark,
                        cardColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Job Fair Info Card
  Widget _buildJobFairInfoCard(
    BuildContext context,
    String title,
    String value,
    String emoji,
    bool isDark,
    Color cardColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Actions Section
  Widget _buildQuickActionsSection(
    BuildContext context,
    Color cardColor,
    Color? textColor,
    Color dividerColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Quick Actions"),
            const SizedBox(height: 20),
            _buildQuickActionItem(
              context,
              Icons.assessment_outlined,
              "View Dashboard",
              "Check your profile overview",
              Colors.blue,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionItem(
              context,
              Icons.work_outline,
              "Browse Jobs",
              "Find available positions",
              Colors.green,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const JobsScreen())),
            ),
            const SizedBox(height: 12),
            _buildQuickActionItem(
              context,
              Icons.people_outline,
              "Visit Companies",
              "Explore company profiles",
              Colors.orange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompaniesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionItem(
              context,
              Icons.help_outline,
              "Get Support",
              "Contact support team",
              Colors.purple,
              onTap: () => _launchEmail(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportLinkItem(
    BuildContext context,
    Color iconColor,
    Color dividerColor,
    IconData icon,
    String title,
    String subtitle,
    IconData trailingIcon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(trailingIcon, size: 14, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }

  // Job Fair Information Section
  Widget _buildJobFairSection(
    BuildContext context,
    Color cardColor,
    Color? textColor,
    Color dividerColor,
  ) {
    final dashboardProvider = Provider.of<StudentProvider>(context);
    final marketOverview = dashboardProvider.dashboardData?.marketOverview;
    final isRegistered =
        dashboardProvider.dashboardData?.studentProfile.isRegisteredForFair ??
        false;

    final fairName = marketOverview?.activeFairSemester ?? "Not Available";
    final companyCount = marketOverview?.totalCompanies ?? 0;
    final jobCount = marketOverview?.totalJobs ?? 0;
    final currentFairDay = marketOverview?.currentFairDay ?? "N/A";
    final currentFairDaysUntil = marketOverview?.currentFairDaysUntil;
    final upcomingFair = marketOverview?.upcomingFair;

    String dayLabel(int? daysUntil) {
      if (daysUntil == null) return "N/A";
      if (daysUntil > 0) return "$daysUntil days until fair";
      if (daysUntil == 0) return "Today";
      return "${daysUntil.abs()} days ago";
    }

    String formatDate(DateTime? value) {
      if (value == null) return "Date not announced";
      final d = value.toLocal();
      return "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Job Fair Information"),
            const SizedBox(height: 20),
            // Current Fair
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Registration",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fairName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$companyCount Companies • $jobCount Positions",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$currentFairDay • ${dayLabel(currentFairDaysUntil)}",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Chip(
                        label: Text(
                          isRegistered ? "Registered" : "Not Registered",
                        ),
                        backgroundColor: isRegistered
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isRegistered
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurple.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: upcomingFair == null
                  ? Row(
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          color: Colors.deepPurple.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "No upcoming job fair announced after current fair.",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Upcoming Job Fair",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upcomingFair.semester,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${upcomingFair.totalCompanies} Companies • ${upcomingFair.totalJobs} Positions",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${formatDate(upcomingFair.date)} • ${dayLabel(upcomingFair.daysUntil)}",
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(
                                upcomingFair.isRegistered
                                    ? "Registered"
                                    : "Not Registered",
                              ),
                              backgroundColor: upcomingFair.isRegistered
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: upcomingFair.isRegistered
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (!upcomingFair.isRegistered) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "If you want to register for this fair, please contact IT Center.",
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
