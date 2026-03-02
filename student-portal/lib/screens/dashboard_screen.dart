import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/dashboard_data.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/profile.dart';
import 'package:intl/intl.dart';
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart';
import 'package:student_job_fair_portal/widgets/notice_board_popup.dart';
import 'package:student_job_fair_portal/screens/settings_screen.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/screens/job_screen.dart';
import 'package:student_job_fair_portal/widgets/interview_status_chart.dart';
import 'package:student_job_fair_portal/widgets/market_overview_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchDashboardData();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<StudentProvider>(
      context,
      listen: false,
    ).fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final dashboardData = studentProvider.dashboardData;
    final isLoading = studentProvider.isLoading;
    final error = studentProvider.dashboardError;
    final student = studentProvider.student;

    // 🔹 Theme Colors
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).primaryColor;

    if (isLoading && dashboardData == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (dashboardData == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  error ?? 'Failed to load dashboard data.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final String? profileImageUrl =
        (student?.profilePicUrl != null && student!.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : "${studentProvider.imageBaseUrl}${student.profilePicUrl!}")
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final isWide = screenWidth > 800;

        if (!isWide) {
          // ==================================================================
          // MOBILE LAYOUT
          // ==================================================================
          return Scaffold(
            backgroundColor: scaffoldBg,
            extendBody: true,
            appBar: BeautifulAppBar(
              title: "Dashboard",
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
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(
                      context,
                      dashboardData.studentProfile,
                      isWide,
                    ),
                    const SizedBox(height: 24),
                    _buildMarketOverview(
                      context,
                      dashboardData.marketOverview,
                      isWide,
                    ),
                    const SizedBox(height: 24),
                    _buildActionsRequired(
                      context,
                      dashboardData.actionsRequired,
                    ),
                    const SizedBox(height: 24),
                    _buildInterviewStats(context, dashboardData.interviewStats),
                    const SizedBox(height: 24),
                    _buildNotices(context, dashboardData.notices),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: const BeautifulMobileNavBar(currentIndex: 0),
          );
        } else {
          // ==================================================================
          // WEB LAYOUT
          // ==================================================================
          return Scaffold(
            backgroundColor: scaffoldBg,
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
                                    "Dashboard",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Left Column
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            _buildProfileSection(
                                              context,
                                              dashboardData.studentProfile,
                                              isWide,
                                            ),
                                            const SizedBox(height: 24),
                                            _buildMarketOverview(
                                              context,
                                              dashboardData.marketOverview,
                                              isWide,
                                            ),
                                            const SizedBox(height: 24),
                                            _buildActionsRequired(
                                              context,
                                              dashboardData.actionsRequired,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      // Right Column
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            _buildInterviewStats(
                                              context,
                                              dashboardData.interviewStats,
                                            ),
                                            const SizedBox(height: 24),
                                            _buildNotices(
                                              context,
                                              dashboardData.notices,
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
                        const SizedBox(height: 20),
                        const WebFooter(),
                      ],
                    ),
                  ),
                ),
                BeautifulWebNavBar(
                  currentRoute: 'Dashboard',
                  profileImageUrl: profileImageUrl,
                  userName: dashboardData.studentProfile.name,
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    StudentProfileSummary profile,
    bool isWide,
  ) {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final String? fullProfileUrl =
        (profile.profilePicUrl != null && profile.profilePicUrl!.isNotEmpty)
        ? (profile.profilePicUrl!.startsWith('http')
              ? profile.profilePicUrl
              : "${studentProvider.imageBaseUrl}${profile.profilePicUrl!}")
        : null;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: fullProfileUrl != null
                    ? NetworkImage(fullProfileUrl)
                    : null,
                child: fullProfileUrl == null
                    ? Text(
                        profile.name.isNotEmpty ? profile.name[0] : '?',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      profile.registrationNo,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    if (profile.completeness == 100)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Profile Complete',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile Completeness',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: profile.completeness / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.orange,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${profile.completeness}%',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    if (!profile.isRegisteredForFair) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          'Not Registered for Job Fair',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketOverview(
    BuildContext context,
    MarketOverview market,
    bool isWide,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Market Overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (market.activeFairSemester != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Active Fair: ${market.activeFairSemester}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Companies',
                market.totalCompanies.toString(),
                Icons.business,
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CompaniesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Total Jobs',
                market.totalJobs.toString(),
                Icons.work,
                Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JobsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: MarketOverviewChart(overview: market),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsRequired(BuildContext context, ActionsRequired actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions Required', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              if (actions.pendingInterviewRequestsCount > 0)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.calendar_today, color: Colors.white),
                  ),
                  title: Text(
                    '${actions.pendingInterviewRequestsCount} Pending Interview Requests',
                  ),
                  subtitle: const Text('Action needed'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to interviews
                  },
                ),
              if (actions.pendingProjectInvitesCount > 0)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.group_add, color: Colors.white),
                  ),
                  title: Text(
                    '${actions.pendingProjectInvitesCount} Pending Project Invites',
                  ),
                  subtitle: const Text('Review invites'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to projects
                  },
                ),
              if (actions.pendingInterviewRequestsCount == 0 &&
                  actions.pendingProjectInvitesCount == 0)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No pending actions. Good job!'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterviewStats(BuildContext context, InterviewStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Interview Stats', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [InterviewStatusChart(stats: stats)]),
          ),
        ),
        const SizedBox(height: 16),
        Text('Next Interview', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (stats.nextInterview == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No upcoming interviews')),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: stats.nextInterview!.companyLogo != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(
                        stats.nextInterview!.companyLogo!,
                      ),
                    )
                  : const CircleAvatar(child: Icon(Icons.business)),
              title: Text(stats.nextInterview!.companyName),
              subtitle: Text(
                stats.nextInterview!.scheduledTime != null
                    ? DateFormat.yMMMd().add_jm().format(
                        stats.nextInterview!.scheduledTime!,
                      )
                    : 'Scheduled',
              ),
              trailing: Chip(label: Text(stats.nextInterview!.status)),
            ),
          ),
      ],
    );
  }

  Widget _buildNotices(BuildContext context, List<NoticeSummary> notices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Notices', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (notices.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No recent notices')),
            ),
          )
        else
          ...notices.map(
            (notice) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  notice.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  notice.createdAt != null
                      ? DateFormat.yMMMd().format(notice.createdAt!)
                      : '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(notice.content),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
