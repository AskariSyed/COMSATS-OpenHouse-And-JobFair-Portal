import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';

// Providers & Widgets
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';

// Screens for Navigation (Needed for Sidebar/Logic consistency)
import 'package:student_job_fair_portal/screens/profile.dart';
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/screens/job_screen.dart';
import 'package:student_job_fair_portal/screens/requestScreen.dart';
import 'package:student_job_fair_portal/widgets/custom_nav_bar.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late List<CollapsibleItem> _sidebarItems;
  final String _currentRoute = 'Queue';
  final String _serverBaseUrl = "http://192.168.137.1:5158";

  // Kept for consistency with other screens' logic
  final List<String> _implementedRoutes = [
    'Profile',
    'Dashboard',
    'Companies',
    'Jobs',
    'Requests',
    'Queue',
  ];

  @override
  void initState() {
    super.initState();
    _sidebarItems = generateSidebarItems(context, setState, _currentRoute);
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    // 🔹 Theme Colors
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String? profileImageUrl =
        (student?.profilePicUrl != null && student!.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : _serverBaseUrl + student.profilePicUrl!)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isMobile = screenWidth < 800;

        if (isMobile) {
          // ==================================================================
          // MOBILE LAYOUT
          // ==================================================================
          return Scaffold(
            backgroundColor: scaffoldBg, // 🔹 Theme
            extendBody: true, // 🔹 Important for floating nav bar
            appBar: const BeautifulAppBar(title: "Interview Queue"),
            body: _buildMessageContent(context, isMobile: true, isDark: isDark),
            bottomNavigationBar: const BeautifulMobileNavBar(
              currentIndex: 3,
            ), // Index 3 for Queue
          );
        } else {
          // ==================================================================
          // WEB LAYOUT
          // ==================================================================
          _sidebarItems = generateSidebarItems(
            context,
            setState,
            _currentRoute,
          );

          return Scaffold(
            backgroundColor: scaffoldBg, // 🔹 Theme
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 100.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _buildMessageContent(
                            context,
                            isMobile: false,
                            isDark: isDark,
                          ),
                        ),
                        const WebFooter(),
                      ],
                    ),
                  ),
                ),

                // 🔹 Beautiful Web Navigation Bar
                BeautifulWebNavBar(
                  currentRoute: 'Queue',
                  profileImageUrl: profileImageUrl,
                  userName: student?.user.fullName ?? "User",
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMessageContent(
    BuildContext context, {
    required bool isMobile,
    required bool isDark,
  }) {
    // Theme-aware colors
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final subTextColor = Theme.of(context).textTheme.bodySmall?.color;
    final warningBg = isDark
        ? Colors.orange.withOpacity(0.1)
        : Colors.orange.shade50;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: warningBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: isMobile ? 60 : 80,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Queue Not Available Yet",
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: textColor, // 🔹 Theme
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                "The interview queue feature is only available on the day of the Job Fair. Please check back then to join queues and manage your interviews.",
                style: TextStyle(
                  fontSize: 16,
                  color: subTextColor, // 🔹 Theme
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  FadePageRoute(page: const CompaniesScreen()),
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Browse Companies"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                side: BorderSide(color: Theme.of(context).primaryColor),
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader(
    BuildContext context,
    dynamic student,
    String? profileImageUrl,
  ) {
    return Container();
  }
}
