import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

// Mixins & Models
import 'package:student_job_fair_portal/mixins/enums.dart';
import 'package:student_job_fair_portal/model/InterviewRequest.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';

// Providers
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/company_profile_screen.dart';

// Screens for Navigation
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart';
import 'package:student_job_fair_portal/widgets/app_animations.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/web_footer.dart';
// 👈 Import for Bottom Nav
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class RequestsScreen extends StatefulWidget {
  final int initialTabIndex; // 0 = Sent, 1 = Received
  final int? highlightedRequestId;

  const RequestsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.highlightedRequestId,
  });

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  // Mobile Tab Controller
  late TabController _tabController;

  // Web State
  int _webTabIndex = 0; // 0 = Sent, 1 = Received
  final String _serverBaseUrl = BackendConfig.serverBaseUrl;

  @override
  void initState() {
    super.initState();
    final safeInitialIndex = widget.initialTabIndex.clamp(0, 1);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: safeInitialIndex,
    );
    _webTabIndex = safeInitialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(
        context,
        listen: false,
      ).fetchInterviewRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Provider.of<StudentProvider>(
      context,
      listen: false,
    ).fetchInterviewRequests();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final requests = studentProvider.interviewRequests;
    final student = studentProvider.student;

    // Separate lists
    final sentRequests = requests
        .where((r) => r.requestedBy == RequestedBy.Student)
        .toList();
    final receivedRequests = requests
        .where((r) => r.requestedBy == RequestedBy.Company)
        .toList();

    if (widget.highlightedRequestId != null) {
      receivedRequests.sort((a, b) {
        final aHighlighted = a.requestId == widget.highlightedRequestId;
        final bHighlighted = b.requestId == widget.highlightedRequestId;
        if (aHighlighted == bHighlighted) return 0;
        return aHighlighted ? -1 : 1;
      });
    }

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

        // ====================================================================
        // MOBILE LAYOUT
        // ====================================================================
        if (isMobile) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: BeautifulAppBar(title: "Interview Requests"),
            body: BeautifulMobileNavBar.withSwipeNavigation(
              context: context,
              currentIndex: 5,
              child: AppPageReveal(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Theme.of(context).primaryColor,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.all(4),
                        tabs: const [
                          Tab(text: "Sent Requests"),
                          Tab(text: "Received Requests"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSentList(
                              sentRequests,
                              studentProvider,
                              isMobile: true,
                            ),
                            _buildReceivedList(
                              receivedRequests,
                              studentProvider,
                              isMobile: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BeautifulMobileNavBar(currentIndex: 5),
          );
        }

        // ====================================================================
        // WEB LAYOUT
        // ====================================================================
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 80,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 30,
                              ),
                              child: AppPageReveal(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Interview Requests",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.blueGrey.shade800,
                                              ),
                                        ),
                                        IconButton(
                                          onPressed: _refresh,
                                          icon: const Icon(Icons.refresh),
                                          tooltip: "Refresh Requests",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildWebTab(
                                            "Sent Requests",
                                            sentRequests.length,
                                            0,
                                          ),
                                          _buildWebTab(
                                            "Received Invites",
                                            receivedRequests.length,
                                            1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    _webTabIndex == 0
                                        ? _buildSentList(
                                            sentRequests,
                                            studentProvider,
                                            isMobile: false,
                                          )
                                        : _buildReceivedList(
                                            receivedRequests,
                                            studentProvider,
                                            isMobile: false,
                                          ),
                                  ],
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
              // 🔹 ADDED: Web Header (Top Bar)
              BeautifulWebNavBar(
                currentRoute: 'Requests', // or 'Jobs', 'Companies', etc.
                profileImageUrl: profileImageUrl,
                userName: student?.user.fullName ?? "User",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebTab(String title, int count, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _webTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _webTabIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Theme.of(context).cardColor : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- List Builders ---

  Widget _buildSentList(
    List<InterviewRequest> requests,
    StudentProvider provider, {
    required bool isMobile,
  }) {
    if (provider.isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (requests.isEmpty) {
      return _buildEmptyState("You haven't sent any interview requests yet.");
    }

    final list = ListView.separated(
      padding: isMobile ? const EdgeInsets.all(16) : EdgeInsets.zero,
      shrinkWrap: !isMobile, // Shrink wrap on web to fit in column
      physics: !isMobile
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final req = requests[i];
        return _buildRequestCard(
          req,
          actions: req.status == RequestStatus.Pending
              ? [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _confirmWithdraw(req.requestId, provider),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              "Withdraw",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]
              : [],
        );
      },
    );

    return isMobile ? RefreshIndicator(onRefresh: _refresh, child: list) : list;
  }

  Widget _buildReceivedList(
    List<InterviewRequest> requests,
    StudentProvider provider, {
    required bool isMobile,
  }) {
    if (provider.isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (requests.isEmpty) {
      return _buildEmptyState("No interview invites from companies yet.");
    }

    final list = ListView.separated(
      padding: isMobile ? const EdgeInsets.all(16) : EdgeInsets.zero,
      shrinkWrap: !isMobile,
      physics: !isMobile
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final req = requests[i];
        List<Widget> actions = [];
        if (req.status == RequestStatus.Pending) {
          actions = [
            OutlinedButton.icon(
              onPressed: () => _showRejectDialog(req.requestId, provider),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 8 : 10,
                ),
                minimumSize: Size(0, isMobile ? 34 : 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.close_rounded, size: isMobile ? 14 : 16),
              label: Text(
                "Decline",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  _handleAction(provider.acceptCompanyInvite(req.requestId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 8 : 10,
                ),
                minimumSize: Size(0, isMobile ? 34 : 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.check_rounded, size: isMobile ? 14 : 16),
              label: Text(
                "Accept",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
          ];
        }
        return _buildRequestCard(
          req,
          actions: actions,
          isReceived: true,
          isHighlighted: req.requestId == widget.highlightedRequestId,
        );
      },
    );

    return isMobile ? RefreshIndicator(onRefresh: _refresh, child: list) : list;
  }

  // --- Card Components ---

  Widget _buildRequestCard(
    InterviewRequest req, {
    List<Widget>? actions,
    bool isReceived = false,
    bool isHighlighted = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final dateStr = DateFormat('MMM d, yyyy').format(req.requestDate);
    final String? logoUrl = (req.logoUrl != null && req.logoUrl!.isNotEmpty)
        ? (req.logoUrl!.startsWith('http')
              ? req.logoUrl
              : "$_serverBaseUrl${req.logoUrl}")
        : null;

    return Card(
      elevation: isDark ? 2 : 4,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      surfaceTintColor: isHighlighted
          ? Colors.amber.withValues(alpha: 0.2)
          : null,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : 0,
        vertical: isMobile ? 6 : 8,
      ),
      // 🔹 NAVIGATION: Click card to visit Company Profile
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompanyProfileScreen(
                companyId: req.companyId,
                companyName: req.companyName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo with Beautiful Fallback
                  Container(
                    width: isMobile ? 50 : 60,
                    height: isMobile ? 50 : 60,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) =>
                                  _buildFallbackIcon(),
                              errorWidget: (context, url, error) =>
                                  _buildFallbackIcon(),
                            )
                          : _buildFallbackIcon(),
                    ),
                  ),
                  if (isHighlighted)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.companyName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (req.industry != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            req.industry!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          isReceived
                              ? "Invited you on $dateStr"
                              : "Sent on $dateStr",
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge and Actions in Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(req.status),
                      if (actions != null && actions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isMobile ? 200 : 240,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: isMobile ? 6 : 8,
                            runSpacing: isMobile ? 6 : 8,
                            children: actions,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (req.status == RequestStatus.Rejected &&
                  req.reasonForReject != null) ...[
                SizedBox(height: isMobile ? 12 : 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.indigo.shade900.withValues(alpha: 0.2)
                        : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.indigo.shade700.withValues(alpha: 0.5)
                          : Colors.indigo.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDark
                            ? Colors.indigo.shade300
                            : Colors.indigo.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Update: ${req.reasonForReject}",
                          style: TextStyle(
                            color: isDark
                                ? Colors.indigo.shade300
                                : Colors.indigo.shade700,
                            fontSize: 13,
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
      ),
    );
  }

  // 🔹 BEAUTIFUL FALLBACK ICON
  Widget _buildFallbackIcon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
      child: Center(
        child: Icon(
          Icons.business,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case RequestStatus.Accepted:
        color = Colors.green;
        text = "Accepted";
        icon = Icons.check_circle_outline;
        break;
      case RequestStatus.Rejected:
        color = Colors.indigo;
        text = "Under Review";
        icon = Icons.hourglass_top;
        break;
      default:
        color = Colors.orange;
        text = "Pending";
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: isMobile ? 180 : 220,
              height: isMobile ? 180 : 220,
              child: Lottie.asset(
                'assets/animations/no_result_found.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Actions ---

  void _confirmWithdraw(int requestId, StudentProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Withdraw Request"),
        content: const Text(
          "Are you sure you want to withdraw this interview request?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(provider.withdrawRequest(requestId));
            },
            child: const Text("Withdraw", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(int requestId, StudentProvider provider) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Decline Invite"),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: "Reason (Optional)",
            hintText: "e.g. Not interested at this time",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(
                provider.rejectCompanyInvite(requestId, reasonCtrl.text),
              );
            },
            child: const Text("Decline", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(Future<String?> action) async {
    final error = await action;
    if (!mounted) return;
    if (error == null) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(message: "Action completed successfully"),
      );
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: error),
      );
    }
  }
}
