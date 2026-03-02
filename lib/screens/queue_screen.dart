import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'dart:async';

// Providers & Widgets
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';

// Screens for Navigation (Needed for Sidebar/Logic consistency)
import 'package:student_job_fair_portal/screens/companies_screen.dart';
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
  Timer? _timer;

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
    // Fetch scheduled interviews when screen loads
    Future.microtask(() {
      final studentProvider = Provider.of<StudentProvider>(
        context,
        listen: false,
      );
      studentProvider.fetchScheduledInterviews();
    });
    // Start timer to update countdown every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              currentIndex: 4,
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
    final studentProvider = Provider.of<StudentProvider>(context);
    final interviews = studentProvider.scheduledInterviews;
    final isLoading = studentProvider.isLoading;
    final error = studentProvider.scheduledInterviewsError;

    // Theme-aware colors
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final subTextColor = Theme.of(context).textTheme.bodySmall?.color;
    final warningBg = isDark
        ? Colors.orange.withValues(alpha: 0.1)
        : Colors.orange.shade50;

    // Show loading indicator
    if (isLoading && interviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              "Loading your interviews...",
              style: TextStyle(color: subTextColor),
            ),
          ],
        ),
      );
    }

    // Show error if any
    if (error != null && interviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: isMobile ? 60 : 80,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Error Loading Interviews",
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(fontSize: 16, color: subTextColor, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show interviews list if available
    if (interviews.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Scheduled Interviews",
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You have ${interviews.length} scheduled interview${interviews.length != 1 ? 's' : ''}",
              style: TextStyle(fontSize: 16, color: subTextColor),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: interviews.length,
              itemBuilder: (context, index) {
                final interview = interviews[index];
                final statusColor = _getStatusColor(interview.status);
                final isUpcoming =
                    interview.scheduledTime?.isAfter(DateTime.now()) ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company header with logo and name
                        Row(
                          children: [
                            if (interview.companyLogo != null &&
                                interview.companyLogo!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  interview.companyLogo!.startsWith('http')
                                      ? interview.companyLogo!
                                      : '$_serverBaseUrl${interview.companyLogo}',
                                  width: isMobile ? 60 : 80,
                                  height: isMobile ? 60 : 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: isMobile ? 60 : 80,
                                      height: isMobile ? 60 : 80,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.business,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    interview.companyName,
                                    style: TextStyle(
                                      fontSize: isMobile ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      interview.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Interview details grid
                        GridView.count(
                          crossAxisCount: isMobile ? 2 : 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: isMobile ? 1.5 : 2.5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _buildDetailCard(
                              icon: Icons.schedule,
                              label: "Scheduled Time",
                              value: interview.scheduledTime != null
                                  ? _formatDateTime(interview.scheduledTime!)
                                  : "TBD",
                              isDark: isDark,
                            ),
                            _buildDetailCard(
                              icon: Icons.access_time,
                              label: "Duration",
                              value: interview.durationMinutes != null
                                  ? "${interview.durationMinutes} mins"
                                  : "TBD",
                              isDark: isDark,
                            ),
                            _buildDetailCard(
                              icon: Icons.location_on,
                              label: "Room",
                              value: interview.room,
                              isDark: isDark,
                            ),
                            _buildDetailCard(
                              icon: Icons.timer,
                              label: "Time Until Interview",
                              value: _getCountdownString(
                                interview.scheduledTime,
                              ),
                              isDark: isDark,
                            ),
                          ],
                        ),
                        if (isUpcoming) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Interview scheduled for the future",
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Show empty state
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
              "No Scheduled Interviews Yet",
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                "You don't have any scheduled interviews yet. Browse companies and send interview requests to get started!",
                style: TextStyle(
                  fontSize: 16,
                  color: subTextColor,
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

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final textColor = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'queued':
        return Colors.blue;
      case 'inprogress':
        return Colors.orange;
      case 'shortlisted':
        return Colors.green;
      case 'hired':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return "${dateTime.day} ${_getMonthName(dateTime.month)} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (difference.inHours > 0) {
      return "Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (difference.inMinutes > 0) {
      return "In ${difference.inMinutes} minutes";
    } else {
      return "Just now";
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _getCountdownString(DateTime? scheduledTime) {
    if (scheduledTime == null) return "TBD";

    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      return "Started";
    } else if (difference.inDays > 0) {
      return "${difference.inDays}d ${difference.inHours % 24}h";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ${difference.inMinutes % 60}m";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ${difference.inSeconds % 60}s";
    } else {
      return "Starting soon";
    }
  }

  Widget _buildWebHeader(
    BuildContext context,
    dynamic student,
    String? profileImageUrl,
  ) {
    return Container();
  }
}
