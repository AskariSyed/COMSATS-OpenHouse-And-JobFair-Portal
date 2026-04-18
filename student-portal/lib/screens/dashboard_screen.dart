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
import 'package:student_job_fair_portal/screens/company_profile_screen.dart';
import 'package:student_job_fair_portal/screens/requestScreen.dart';
import 'package:student_job_fair_portal/widgets/interview_status_chart.dart';
import 'package:student_job_fair_portal/widgets/market_overview_chart.dart';
import 'package:student_job_fair_portal/widgets/app_animations.dart';
import 'package:student_job_fair_portal/services/cv_generator.dart';
import 'package:student_job_fair_portal/widgets/cv_editor_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasShownCvPrompt = false;
  bool _hasInitialDashboardFetchCompleted = false;

  Widget _buildDashboardCard(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? margin,
    Clip clipBehavior = Clip.none,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: margin,
      elevation: isDark ? 3 : 6,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.32)
          : Colors.black.withValues(alpha: 0.10),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE5E7EB),
        ),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
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
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: 'Error selecting/uploading PDF: $e'),
      );
    }
  }

  Future<void> _loadInitialDashboard() async {
    final provider = Provider.of<StudentProvider>(context, listen: false);
    provider.fetchProfile();
    provider.fetchInterviewRequests();
    provider.fetchScheduledInterviews();
    await provider.fetchDashboardData();
    if (mounted) {
      setState(() {
        _hasInitialDashboardFetchCompleted = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDashboard();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<StudentProvider>(
      context,
      listen: false,
    ).fetchDashboardData();
  }

  Future<void> _promptUploadCv() async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );

    final shouldUploadNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile Complete 🎉'),
        content: const Text(
          'Your profile is complete. Upload your CV now so companies can view it. You can upload generated CV or your own PDF.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Upload CV'),
          ),
        ],
      ),
    );
    if (shouldUploadNow != true || !mounted) {
      studentProvider.markCvUploadPromptSkippedForSession();
      return;
    }
    if (shouldUploadNow != true || !mounted) return;

    final uploadChoice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose CV Upload Option'),
        content: const Text('Select one option to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'generated'),
            child: const Text('Generate & Upload CV'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'own'),
            child: const Text('Upload My Own PDF'),
          ),
        ],
      ),
    );

    if (!mounted || uploadChoice == null) {
      studentProvider.markCvUploadPromptSkippedForSession();
      return;
    }

    if (uploadChoice == 'own') {
      await _pickAndUploadOwnCv();
      return;
    }

    final String? cvEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => const CVEditorDialog(),
    );
    if (!mounted || cvEmail == null) return;
    await _uploadGeneratedCvFlow(cvEmail: cvEmail);
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final dashboardData = studentProvider.dashboardData;
    if (dashboardData != null) {
      final providerCv = studentProvider.student?.cvUrl?.trim() ?? '';
      final studentCvMissing = providerCv.isEmpty;

      if (!_hasShownCvPrompt &&
          !studentProvider.hasSkippedCvUploadPromptThisSession &&
          dashboardData.studentProfile.completeness >= 100 &&
          studentCvMissing) {
        _hasShownCvPrompt = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _promptUploadCv();
          }
        });
      }
    }

    final isLoading = studentProvider.isLoading;
    final error = studentProvider.dashboardError;
    final student = studentProvider.student;

    // 🔹 Theme Colors
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    if (dashboardData == null &&
        (isLoading || !_hasInitialDashboardFetchCompleted)) {
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
            body: BeautifulMobileNavBar.withSwipeNavigation(
              context: context,
              currentIndex: 0,
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: AppPageReveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileSection(
                          context,
                          dashboardData.studentProfile,
                          dashboardData.marketOverview,
                          isWide,
                        ),
                        const SizedBox(height: 24),
                        _buildMarketOverview(
                          context,
                          dashboardData.marketOverview,
                          isWide,
                        ),
                        const SizedBox(height: 24),
                        _buildRecommendedJobs(
                          context,
                          dashboardData.recommendedJobs,
                        ),
                        const SizedBox(height: 24),
                        _buildActionsRequired(
                          context,
                          dashboardData.actionsRequired,
                        ),
                        const SizedBox(height: 24),
                        _buildInterviewStats(
                          context,
                          dashboardData.interviewStats,
                        ),
                        const SizedBox(height: 24),
                        _buildNotices(context, dashboardData.notices),
                      ],
                    ),
                  ),
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
                              child: AppPageReveal(
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
                                          ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildProfileSection(
                                                context,
                                                dashboardData.studentProfile,
                                                dashboardData.marketOverview,
                                                isWide,
                                              ),
                                              const SizedBox(height: 24),
                                              _buildMarketOverview(
                                                context,
                                                dashboardData.marketOverview,
                                                isWide,
                                              ),
                                              const SizedBox(height: 24),
                                              _buildRecommendedJobs(
                                                context,
                                                dashboardData.recommendedJobs,
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
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
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
                        ),
                        const SizedBox(height: 20),
                        // FYP Disclaimer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            '📚 Disclaimer: This is a Final Year Project by COMSATS Students (Class of 2026) and does not refer to any official COMSATS platform, policy, or communication.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
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
    MarketOverview marketOverview,
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

    final int? daysUntilFair =
        marketOverview.upcomingFair?.daysUntil ??
        marketOverview.currentFairDaysUntil ??
        marketOverview.currentFairDate?.difference(DateTime.now()).inDays;

    return _buildDashboardCard(
      context,
      clipBehavior: Clip.antiAlias,
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
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: fullProfileUrl != null
                      ? CachedNetworkImage(
                          imageUrl: fullProfileUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              profile.name.isNotEmpty ? profile.name[0] : '?',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0] : '?',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
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
                          color: Colors.green.withValues(alpha: 0.1),
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
                    if (profile.completeness < 100) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Text(
                          daysUntilFair != null && daysUntilFair >= 0
                              ? 'Please complete your profile well in time. '
                                    '$daysUntilFair day${daysUntilFair == 1 ? '' : 's'} left until the Job Fair.'
                              : 'Please complete your profile well in time for the Job Fair to improve visibility for recruiters.',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.amber.shade100
                                : Colors.amber.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
    final statsSection = Row(
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
    );

    final chartCard = _buildDashboardCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: isWide ? 280 : 220,
          child: AppLoadingFadeIn(child: MarketOverviewChart(overview: market)),
        ),
      ),
    );

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
        if (isWide)
          Column(
            children: [statsSection, const SizedBox(height: 16), chartCard],
          )
        else
          Column(
            children: [statsSection, const SizedBox(height: 16), chartCard],
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
    return _buildDashboardCard(
      context,
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
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
        SizedBox(
          width: double.infinity,
          child: _buildDashboardCard(
            context,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const RequestsScreen(initialTabIndex: 1),
                        ),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(
                            focusProjectInvitations: true,
                          ),
                        ),
                      );
                    },
                  ),
                if (actions.pendingInterviewRequestsCount == 0 &&
                    actions.pendingProjectInvitesCount == 0)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No pending actions. Good job!')),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedJobs(
    BuildContext context,
    List<RecommendedJob> jobs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommended Jobs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildDashboardCard(
          context,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: jobs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Add more profile skills to get personalized job recommendations.',
                    ),
                  )
                : Column(
                    children: jobs.map((job) {
                      final logoUrl =
                          job.companyLogo != null && job.companyLogo!.isNotEmpty
                          ? (job.companyLogo!.startsWith('http')
                                ? job.companyLogo!
                                : BackendConfig.absoluteUrl(job.companyLogo))
                          : '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: logoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: logoUrl,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.business),
                                  ),
                                )
                              : const Icon(Icons.work_outline),
                        ),
                        title: Text(job.jobTitle),
                        subtitle: Text(
                          '${job.companyName} • ${job.matchCount} skill match${job.matchCount > 1 ? 'es' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (job.companyId > 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CompanyProfileScreen(
                                  companyId: job.companyId,
                                  companyName: job.companyName,
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JobsScreen(),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterviewStats(BuildContext context, InterviewStats stats) {
    final pendingCount = stats.pendingRequests.length;
    final acceptedCount = stats.acceptedRequests.length;
    final scheduledCount = stats.allInterviews
        .where(
          (i) => i.status.toLowerCase() != 'pending' && i.scheduledTime != null,
        )
        .length;
    final hasInterviewChartData =
        pendingCount > 0 || acceptedCount > 0 || scheduledCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Interview Stats', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildDashboardCard(
          context,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                hasInterviewChartData
                    ? AppPieChartReveal(
                        child: InterviewStatusChart(stats: stats),
                      )
                    : InterviewStatusChart(stats: stats),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Next Interview', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (stats.nextInterview == null)
          _buildDashboardCard(
            context,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No upcoming interviews')),
            ),
          )
        else
          _buildDashboardCard(
            context,
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
          _buildDashboardCard(
            context,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No recent notices')),
            ),
          )
        else
          ...notices.map(
            (notice) => _buildDashboardCard(
              context,
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
