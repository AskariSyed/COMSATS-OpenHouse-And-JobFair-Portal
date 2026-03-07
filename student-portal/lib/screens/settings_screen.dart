import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// Providers & Widgets
import 'package:student_job_fair_portal/provider/theme_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/provider/notification_provider.dart';
import 'package:student_job_fair_portal/utils/password_validator.dart';
import 'package:student_job_fair_portal/screens/sigin.dart';
import 'package:student_job_fair_portal/screens/notifications_screen.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart';
import 'package:student_job_fair_portal/widgets/notice_board_popup.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart';
import 'package:student_job_fair_portal/widgets/cv_editor_dialog.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/services/cv_generator.dart';

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
    return 'http://192.168.137.1:5158$cvUrl';
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

      if (kIsWeb) {
        await CVGenerator.previewPdfOnWeb(pdfBytes);
        if (context.mounted) {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.success(
              message: 'CV preview opened in a new browser tab.',
            ),
          );
        }
        return;
      }

      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: SizedBox(
            width: isMobile ? double.infinity : 900,
            height: isMobile ? 600 : 700,
            child: SfPdfViewer.memory(pdfBytes),
          ),
        ),
      );
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
              : "http://192.168.137.1:5158${student.profilePicUrl}")
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
          Padding(
            padding: const EdgeInsets.only(top: 80.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 30,
                        ),
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
                  const SizedBox(height: 20),
                  const WebFooter(),
                ],
              ),
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
                tooltip: 'Upload Generated CV',
                colors: [Colors.teal.shade600, Colors.teal.shade800],
                isMobile: isMobile,
                onTap: () => _handleUploadGeneratedCv(context),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 360;
    final isMidMobile = screenWidth >= 360 && screenWidth < 600;
    final isLargeMobile = screenWidth >= 600 && screenWidth < 900;
    final isWeb = screenWidth >= 900;

    // Responsive sizing
    final dialogWidth = isWeb
        ? 500.0
        : isLargeMobile
        ? screenWidth * 0.85
        : isMidMobile
        ? screenWidth * 0.90
        : screenWidth * 0.95;

    final iconSize = isSmallMobile ? 20.0 : 24.0;
    final iconPadding = isSmallMobile ? 6.0 : 8.0;
    final titleFontSize = isSmallMobile ? 16.0 : (isMidMobile ? 18.0 : 20.0);
    final labelFontSize = isSmallMobile ? 12.0 : (isMidMobile ? 13.0 : 14.0);
    final fieldSpacing = isSmallMobile ? 12.0 : 16.0;
    final contentPadding = isSmallMobile
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
            ),
            backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
            child: Container(
              width: dialogWidth,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
              ),
              constraints: BoxConstraints(
                maxWidth: isWeb ? 500 : double.infinity,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Container(
                    padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Color(0xFF2563EB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isSmallMobile ? 16 : 20),
                        topRight: Radius.circular(isSmallMobile ? 16 : 20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(iconPadding),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.lock_reset,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),
                        SizedBox(width: isSmallMobile ? 8 : 12),
                        Expanded(
                          child: Text(
                            'Change Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: currentPasswordController,
                            obscureText: !showCurrentPassword,
                            style: TextStyle(fontSize: labelFontSize),
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              labelStyle: TextStyle(fontSize: labelFontSize),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: iconSize,
                                color: Color(0xFF2563EB),
                              ),
                              suffixIcon: IconButton(
                                iconSize: iconSize,
                                icon: Icon(
                                  showCurrentPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showCurrentPassword = !showCurrentPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: contentPadding,
                            ),
                          ),
                          SizedBox(height: fieldSpacing),
                          TextField(
                            controller: newPasswordController,
                            obscureText: !showNewPassword,
                            style: TextStyle(fontSize: labelFontSize),
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              labelStyle: TextStyle(fontSize: labelFontSize),
                              prefixIcon: Icon(
                                Icons.lock,
                                size: iconSize,
                                color: Color(0xFF2563EB),
                              ),
                              suffixIcon: IconButton(
                                iconSize: iconSize,
                                icon: Icon(
                                  showNewPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showNewPassword = !showNewPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: contentPadding,
                            ),
                          ),
                          SizedBox(height: fieldSpacing),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: !showConfirmPassword,
                            style: TextStyle(fontSize: labelFontSize),
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              labelStyle: TextStyle(fontSize: labelFontSize),
                              prefixIcon: Icon(
                                Icons.lock_clock,
                                size: iconSize,
                                color: Color(0xFF2563EB),
                              ),
                              suffixIcon: IconButton(
                                iconSize: iconSize,
                                icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showConfirmPassword = !showConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: contentPadding,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  Container(
                    padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallMobile ? 12 : 20,
                              vertical: isSmallMobile ? 8 : 12,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallMobile ? 8 : 12),
                        ElevatedButton(
                          onPressed: () async {
                            final current = currentPasswordController.text
                                .trim();
                            final newPass = newPasswordController.text.trim();
                            final confirm = confirmPasswordController.text
                                .trim();

                            if (current.isEmpty ||
                                newPass.isEmpty ||
                                confirm.isEmpty) {
                              showTopSnackBar(
                                Overlay.of(context),
                                const CustomSnackBar.error(
                                  message: 'All fields are required',
                                ),
                              );
                              return;
                            }

                            // Validate new password strength
                            final passwordError = PasswordValidator.validate(
                              newPass,
                            );
                            if (passwordError != null) {
                              showTopSnackBar(
                                Overlay.of(context),
                                CustomSnackBar.error(message: passwordError),
                              );
                              return;
                            }

                            if (newPass != confirm) {
                              showTopSnackBar(
                                Overlay.of(context),
                                const CustomSnackBar.error(
                                  message: 'New passwords do not match',
                                ),
                              );
                              return;
                            }

                            try {
                              final studentProvider =
                                  Provider.of<StudentProvider>(
                                    context,
                                    listen: false,
                                  );
                              await studentProvider.changePassword(
                                current,
                                newPass,
                                confirm,
                              );

                              if (context.mounted) {
                                Navigator.of(ctx).pop();
                                showTopSnackBar(
                                  Overlay.of(context),
                                  const CustomSnackBar.success(
                                    message: 'Password changed successfully!',
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                String errorMessage = e.toString();
                                // Remove 'Exception: ' prefix if present
                                if (errorMessage.startsWith('Exception: ')) {
                                  errorMessage = errorMessage.substring(11);
                                }
                                showTopSnackBar(
                                  Overlay.of(context),
                                  CustomSnackBar.error(message: errorMessage),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallMobile ? 16 : 24,
                              vertical: isSmallMobile ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isSmallMobile ? 'Change' : 'Change Password',
                            style: TextStyle(fontSize: labelFontSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
}
