import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Providers & Widgets
import 'package:student_job_fair_portal/provider/theme_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/provider/notification_provider.dart';
import 'package:student_job_fair_portal/screens/sigin.dart';
import 'package:student_job_fair_portal/screens/notifications_screen.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart';
import 'package:student_job_fair_portal/widgets/cv_editor_dialog.dart';
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
        Theme.of(context).iconTheme.color?.withOpacity(0.7) ?? Colors.grey;

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
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      Colors.purple.shade900.withOpacity(0.3),
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
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
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
                          .withOpacity(0.3),
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
              activeColor: primaryColor,
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
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
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
                        color: Colors.blue.withOpacity(0.3),
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
                child: Divider(height: 1, color: dividerColor.withOpacity(0.2)),
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
                        color: Colors.green.withOpacity(0.3),
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
                child: Divider(height: 1, color: dividerColor.withOpacity(0.2)),
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
                        color: Colors.orange.withOpacity(0.3),
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
                child: Divider(height: 1, color: dividerColor.withOpacity(0.2)),
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
                        color: Colors.purple.withOpacity(0.3),
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
                child: Divider(height: 1, color: dividerColor.withOpacity(0.2)),
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
                        color: Colors.teal.withOpacity(0.3),
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

        const SizedBox(height: 30),

        // ----------------------------------------------------------------
        // SAVE PROFILE AS PDF
        // ----------------------------------------------------------------
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final studentProvider = Provider.of<StudentProvider>(
                  context,
                  listen: false,
                );
                final student = studentProvider.student;

                if (student != null) {
                  // Ask user if they want to edit CV before downloading
                  final shouldEdit = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Download CV'),
                      content: const Text(
                        'Would you like to review and edit your CV before downloading?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('No, Download Now'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Yes, Edit First'),
                        ),
                      ],
                    ),
                  );

                  // If user wants to edit, show the CV editor dialog
                  String? customEmail;
                  if (shouldEdit == true && context.mounted) {
                    customEmail = await showDialog<String>(
                      context: context,
                      builder: (ctx) => const CVEditorDialog(),
                    );
                  }

                  // Generate CV after editing (or directly if user chose not to edit)
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generating CV...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    try {
                      // Refresh student data in case changes were made
                      await studentProvider.fetchProfile();
                      final updatedStudent = studentProvider.student;
                      if (updatedStudent != null) {
                        await CVGenerator.generateAndSaveCV(
                          updatedStudent,
                          customEmail: customEmail,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 14 : 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_download_rounded,
                      color: Colors.white,
                      size: isMobile ? 18 : 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Save Profile as PDF",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ----------------------------------------------------------------
        // SHARE PROFILE AS PDF
        // ----------------------------------------------------------------
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final studentProvider = Provider.of<StudentProvider>(
                  context,
                  listen: false,
                );
                final student = studentProvider.student;

                if (student != null) {
                  // Ask user if they want to edit CV before sharing
                  final shouldEdit = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Share Profile'),
                      content: const Text(
                        'Would you like to review and edit your CV before sharing?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('No, Share Now'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Yes, Edit First'),
                        ),
                      ],
                    ),
                  );

                  // If user wants to edit, show the CV editor dialog
                  String? customEmail;
                  if (shouldEdit == true && context.mounted) {
                    customEmail = await showDialog<String>(
                      context: context,
                      builder: (ctx) => const CVEditorDialog(),
                    );
                  }

                  // Generate and share CV
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preparing CV for sharing...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    try {
                      // Refresh student data
                      await studentProvider.fetchProfile();
                      final updatedStudent = studentProvider.student;
                      if (updatedStudent != null) {
                        // Use CVGenerator.shareCV to show system share sheet
                        // This will show WhatsApp, Messenger, Instagram, etc. on mobile
                        await CVGenerator.shareCV(
                          updatedStudent,
                          customEmail: customEmail,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 14 : 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: isMobile ? 18 : 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Share Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ----------------------------------------------------------------
        // LOGOUT BUTTON
        // ----------------------------------------------------------------
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade800],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await Provider.of<StudentProvider>(
                  context,
                  listen: false,
                ).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const StudentLoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 14 : 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: isMobile ? 18 : 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ----------------------------------------------------------------
        // 3. DEVELOPER CREDITS
        // ----------------------------------------------------------------
        _buildSectionHeader(context, "Meet the Team"),
        isMobile
            ? Column(
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
              )
            : Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _developers
                    .map(
                      (dev) => SizedBox(
                        width:
                            (MediaQuery.of(context).size.width - 80 - 32) / 2,
                        child: _buildDeveloperCard(
                          context,
                          dev,
                          isDark,
                          cardColor,
                          primaryColor,
                          textColor,
                          dividerColor,
                          isMobile,
                        ),
                      ),
                    )
                    .toList(),
              ),
        const SizedBox(height: 50),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: isMobile ? 14 : 16,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  "Version 1.0.0",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: primaryColor,
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isMobile ? 20 : 40),
      ],
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
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isMobile ? 50 : 60,
              height: isMobile ? 50 : 60,
              decoration: BoxDecoration(
                color: devColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: devColor.withOpacity(0.3), width: 2),
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
                      color: devColor.withOpacity(0.1),
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
