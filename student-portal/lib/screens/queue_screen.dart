import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Providers & Widgets
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/model/interview.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/app_animations.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';

// Screens for Navigation (Needed for Sidebar/Logic consistency)
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/widgets/custom_nav_bar.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final String _serverBaseUrl = BackendConfig.serverBaseUrl;
  Timer? _timer;
  final Set<String> _sendingQueueActions = <String>{};
  final Set<int> _expandedCardIds = <int>{};

  void _toggleCard(int id) {
    setState(() {
      if (_expandedCardIds.contains(id)) {
        _expandedCardIds.remove(id);
      } else {
        _expandedCardIds.add(id);
      }
    });
  }

  String _getFormattedCountdown(DateTime? scheduledTime) {
    if (scheduledTime == null) return "TBD";
    final now = DateTime.now();
    final diff = scheduledTime.difference(now);
    final bool isFuture = !diff.isNegative;
    final absDiff = diff.abs();

    if (absDiff.inMinutes < 1) {
      return isFuture ? "Starting now" : "Just started";
    }

    final String timeStr;
    if (absDiff.inHours > 0) {
      timeStr = "${absDiff.inHours}h ${absDiff.inMinutes % 60}m";
    } else {
      timeStr = "${absDiff.inMinutes}m";
    }

    return isFuture ? "Starts in $timeStr" : "Started $timeStr ago";
  }

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
            appBar: const BeautifulAppBar(title: "Interviews"),
            body: BeautifulMobileNavBar.withSwipeNavigation(
              context: context,
              currentIndex: 4,
              child: AppPageReveal(
                child: _buildMessageContent(
                  context,
                  isMobile: true,
                  isDark: isDark,
                ),
              ),
            ),
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 100,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  child: _buildMessageContent(
                                    context,
                                    isMobile: false,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const WebFooter(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 🔹 Beautiful Web Navigation Bar
                BeautifulWebNavBar(
                  currentRoute: 'Interviews',
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
    final interviews = List<Interview>.from(studentProvider.scheduledInterviews)
      ..sort((a, b) {
        final statusCmp = _getStatusPriority(
          a.status,
        ).compareTo(_getStatusPriority(b.status));
        if (statusCmp != 0) return statusCmp;

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
              "Your Interviews",
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Showing upcoming, in-progress, shortlisted, hired, under-review and no-show interviews",
              style: TextStyle(fontSize: 16, color: subTextColor),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: interviews.length,
              itemBuilder: (context, index) {
                final interview = interviews[index];
                return AppStaggeredReveal(
                  index: index,
                  child: _buildInterviewQueueCard(
                    interview: interview,
                    isMobile: isMobile,
                    isDark: isDark,
                    isExpanded: _expandedCardIds.contains(
                      interview.interviewId,
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
              "No Interviews Yet",
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
    required Interview interview,
    required bool isMobile,
    required bool isDark,
    bool isExpanded = false,
  }) {
    final statusColor = _getStatusColor(interview.status);
    final cardBg = isDark ? Colors.grey.shade900 : Colors.white;
    final cardBorder = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final logoSize = isMobile ? 56.0 : 68.0;
    final isQueued = interview.status.toLowerCase() == 'queued';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isMobile ? () => _toggleCard(interview.interviewId) : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  interview.companyName,
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isMobile && isQueued)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      _getFormattedCountdown(
                                        interview.scheduledTime,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                                  _getStatusLabel(interview.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              if (isMobile)
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (isMobile)
                        _buildMobileCardContent(interview, isExpanded, isDark)
                      else
                        _buildWebCardContent(interview, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardContent(
    Interview interview,
    bool isExpanded,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildMobileDetailRow(
                icon: Icons.play_circle_outline,
                label: 'Scheduled Start',
                value: interview.scheduledTime != null
                    ? _formatActualDateTime(interview.scheduledTime!)
                    : 'TBD',
              ),
              const SizedBox(height: 8),
              _buildMobileDetailRow(
                icon: Icons.meeting_room_outlined,
                label: 'Room',
                value: interview.room,
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                _buildMobileDetailRow(
                  icon: Icons.login_outlined,
                  label: 'Actual Start',
                  value: interview.startedAt != null
                      ? _formatActualDateTime(interview.startedAt!)
                      : 'TBD',
                ),
                const SizedBox(height: 8),
                _buildMobileDetailRow(
                  icon: Icons.logout_outlined,
                  label: 'Ended At',
                  value: interview.endedAt != null
                      ? _formatActualDateTime(interview.endedAt!)
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
              ],
            ],
          ),
        ),
        if (isExpanded && _showQuickStudentActions(interview)) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "Actions",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              _buildNotificationMenu(interview),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildWebCardContent(Interview interview, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQueueInfoPill(
              icon: Icons.play_circle_outline,
              label: 'Scheduled Start',
              value: interview.scheduledTime != null
                  ? _formatActualDateTime(interview.scheduledTime!)
                  : 'TBD',
              isDark: isDark,
            ),
            _buildQueueInfoPill(
              icon: Icons.login_outlined,
              label: 'Actual Start',
              value: interview.startedAt != null
                  ? _formatActualDateTime(interview.startedAt!)
                  : 'TBD',
              isDark: isDark,
            ),
            _buildQueueInfoPill(
              icon: Icons.logout_outlined,
              label: 'Ended At',
              value: interview.endedAt != null
                  ? _formatActualDateTime(interview.endedAt!)
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
          ],
        ),
        if (_showQuickStudentActions(interview)) ...[
          const SizedBox(height: 12),
          _buildNotificationMenu(interview),
        ],
      ],
    );
  }

  Widget _buildNotificationMenu(Interview interview) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Send Update to Company',
      onSelected: (value) => _sendQueueAction(interview, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'StudentArrivingSoon',
          child: _buildPopupItem(
            Icons.directions_walk,
            'I am Coming',
            Colors.green,
          ),
        ),
        PopupMenuItem(
          value: 'StudentArrived',
          child: _buildPopupItem(
            Icons.how_to_reg,
            'I have Arrived',
            Colors.blue,
          ),
        ),
        PopupMenuItem(
          value: 'StudentRunningLate',
          child: _buildPopupItem(
            Icons.watch_later_outlined,
            'Running Late',
            Colors.orange,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'StudentRescheduleRequest',
          child: _buildPopupItem(
            Icons.notification_important_outlined,
            'Request Reschedule',
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
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
        return Colors.indigo;
      case 'didnotappear':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
        return 'In Progress';
      case 'rejected':
        return 'Under Review';
      case 'didnotappear':
        return 'Did Not Appear';
      default:
        return status;
    }
  }

  bool _showQuickStudentActions(Interview interview) {
    final status = interview.status.toLowerCase();
    // Show actions for queued (upcoming) or currently interviewing students
    return status == 'queued' || status == 'inprogress';
  }

  Future<void> _sendQueueAction(Interview interview, String type) async {
    final key = '${interview.interviewId}_$type';
    if (_sendingQueueActions.contains(key)) return;

    setState(() => _sendingQueueActions.add(key));

    final provider = Provider.of<StudentProvider>(context, listen: false);
    final error = await provider.notifyCompanyForInterviewUpdate(
      interviewId: interview.interviewId,
      type: type,
    );

    if (!mounted) return;
    setState(() => _sendingQueueActions.remove(key));

    final isComing = type == 'StudentArrivingSoon';
    final isArrived = type == 'StudentArrived';
    final isLate = type == 'StudentRunningLate';

    String successText = 'Notification sent to company.';
    if (isComing) successText = 'Company notified that you are on your way.';
    if (isArrived) successText = 'Company notified that you have arrived.';
    if (isLate) successText = 'Company notified that you are running late.';
    if (type == 'StudentRescheduleRequest')
      successText = 'Reschedule request sent to company.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? successText),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
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

  int _getStatusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'queued':
        return 0;
      case 'inprogress':
        return 1;
      case 'shortlisted':
        return 2;
      case 'hired':
        return 3;
      case 'rejected':
        return 4;
      case 'didnotappear':
        return 5;
      default:
        return 6;
    }
  }
}
