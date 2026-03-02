import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Providers & Widgets
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/web_footer.dart';

// Screens for Navigation (Needed for Sidebar/Logic consistency)
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/widgets/custom_nav_bar.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final String _serverBaseUrl = "http://192.168.137.1:5158";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
            backgroundColor: scaffoldBg,
            extendBody: true,
            appBar: const BeautifulAppBar(title: "Interview Queue"),
            body: _buildMessageContent(context, isMobile: true, isDark: isDark),
            bottomNavigationBar: const BeautifulMobileNavBar(currentIndex: 4),
          );
        } else {
          // ==================================================================
          // WEB LAYOUT
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
                        _buildMessageContent(
                          context,
                          isMobile: false,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
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
    final queueInterviews =
        interviews
            .where(
              (i) =>
                  i.status.toLowerCase() == 'queued' ||
                  i.status.toLowerCase() == 'inprogress',
            )
            .toList()
          ..sort((a, b) {
            final aTime = a.scheduledTime;
            final bTime = b.scheduledTime;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });
    final isLoading = studentProvider.isLoading;
    final error = studentProvider.scheduledInterviewsError;

    // Theme-aware colors
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final subTextColor = Theme.of(context).textTheme.bodySmall?.color;
    final warningBg = isDark
        ? Colors.orange.withValues(alpha: 0.1)
        : Colors.orange.shade50;

    // Show loading indicator
    if (isLoading && queueInterviews.isEmpty) {
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
    if (error != null && queueInterviews.isEmpty) {
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
    if (queueInterviews.isNotEmpty) {
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
              "You have ${queueInterviews.length} interview${queueInterviews.length != 1 ? 's' : ''} in queue",
              style: TextStyle(fontSize: 16, color: subTextColor),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: queueInterviews.length,
              itemBuilder: (context, index) {
                final interview = queueInterviews[index];
                return _buildInterviewQueueCard(
                  interview: interview,
                  isMobile: isMobile,
                  isDark: isDark,
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

  Widget _buildInterviewQueueCard({
    required dynamic interview,
    required bool isMobile,
    required bool isDark,
  }) {
    final statusColor = _getStatusColor(interview.status);
    final cardBg = isDark ? Colors.grey.shade900 : Colors.white;
    final cardBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final logoSize = isMobile ? 56.0 : 68.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompanyLogo(interview, logoSize),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        interview.companyName,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        interview.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (isMobile)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildMobileDetailRow(
                          icon: Icons.play_circle_outline,
                          label: 'Start Time',
                          value: interview.scheduledTime != null
                              ? _formatActualDateTime(interview.scheduledTime!)
                              : 'TBD',
                        ),
                        const SizedBox(height: 8),
                        _buildMobileDetailRow(
                          icon: Icons.access_time,
                          label: 'Duration',
                          value: interview.durationMinutes != null
                              ? '${interview.durationMinutes} mins'
                              : 'TBD',
                        ),
                        const SizedBox(height: 8),
                        _buildMobileDetailRow(
                          icon: Icons.meeting_room_outlined,
                          label: 'Room',
                          value: interview.room,
                        ),
                        const SizedBox(height: 8),
                        _buildMobileDetailRow(
                          icon: Icons.timer_outlined,
                          label: 'Time Left',
                          value: _getRemainingTimeString(
                            interview.scheduledTime,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQueueInfoPill(
                        icon: Icons.play_circle_outline,
                        label: 'Start',
                        value: interview.scheduledTime != null
                            ? _formatActualDateTime(interview.scheduledTime!)
                            : 'TBD',
                        isDark: isDark,
                      ),
                      _buildQueueInfoPill(
                        icon: Icons.access_time,
                        label: 'Duration',
                        value: interview.durationMinutes != null
                            ? '${interview.durationMinutes} mins'
                            : 'TBD',
                        isDark: isDark,
                      ),
                      _buildQueueInfoPill(
                        icon: Icons.meeting_room_outlined,
                        label: 'Room',
                        value: interview.room,
                        isDark: isDark,
                      ),
                      _buildQueueInfoPill(
                        icon: Icons.timer_outlined,
                        label: 'Time Left',
                        value: _getRemainingTimeString(interview.scheduledTime),
                        isDark: isDark,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogo(dynamic interview, double logoSize) {
    if (interview.companyLogo != null && interview.companyLogo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          interview.companyLogo!.startsWith('http')
              ? interview.companyLogo!
              : '$_serverBaseUrl${interview.companyLogo}',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildLogoFallback(logoSize),
        ),
      );
    }

    return _buildLogoFallback(logoSize);
  }

  Widget _buildLogoFallback(double logoSize) {
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.business, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildQueueInfoPill({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final bg = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final labelColor = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      constraints: const BoxConstraints(minWidth: 148, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

  String _formatActualDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return "${local.day.toString().padLeft(2, '0')} ${_getMonthName(local.month)} ${local.year}, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
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

  String _getRemainingTimeString(DateTime? scheduledTime) {
    if (scheduledTime == null) return "TBD";

    final now = DateTime.now();
    final difference = scheduledTime.toLocal().difference(now);

    if (difference.isNegative) {
      return "Interview started";
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
}
