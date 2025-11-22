import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';

// Mixins & Models
import 'package:student_job_fair_portal/mixins/enums.dart';
import 'package:student_job_fair_portal/model/InterviewRequest.dart';

// Providers
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/complete_profile_screen.dart';

// Screens for Navigation
import 'package:student_job_fair_portal/screens/profile.dart';
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/screens/job_screen.dart';
import 'package:student_job_fair_portal/widgets/custom_nav_bar.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/widgets/build_bottom_navbar.dart'; // 👈 Import for Bottom Nav
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  // Mobile Tab Controller
  late TabController _tabController;

  // Web State
  int _webTabIndex = 0; // 0 = Sent, 1 = Received
  late List<CollapsibleItem> _sidebarItems;
  final String _serverBaseUrl = "http://192.168.137.1:5158";

  final List<String> _implementedRoutes = [
    'Profile',
    'Dashboard',
    'Companies',
    'Jobs',
    'Requests',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize Sidebar for Web
    _sidebarItems = generateSidebarItems(context, setState, 'Requests');

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
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: const Text(
                "Interview Requests",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: [
                  Tab(text: "Sent (${sentRequests.length})"),
                  Tab(text: "Received (${receivedRequests.length})"),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildSentList(sentRequests, studentProvider, isMobile: true),
                _buildReceivedList(
                  receivedRequests,
                  studentProvider,
                  isMobile: true,
                ),
              ],
            ),
            // 🔹 ADDED: Bottom Navigation Bar for Mobile
            bottomNavigationBar: buildBottomNav(context, 4),
          );
        }

        // ====================================================================
        // WEB LAYOUT
        // ====================================================================
        return Scaffold(
          backgroundColor: Colors.white,
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
                              vertical: 40,
                              horizontal: 30,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Refresh Row
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
                                            color: Colors.blueGrey.shade800,
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

                                // Custom Web Tabs
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
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

                                // List Content
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
                      const SizedBox(height: 40),
                      const WebFooter(),
                    ],
                  ),
                ),
              ),
              // 🔹 ADDED: Web Header (Top Bar)
              _buildWebHeader(context, student, profileImageUrl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebTab(String title, int count, int index) {
    final isSelected = _webTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _webTabIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
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
                  TextButton.icon(
                    onPressed: () => _confirmWithdraw(req.requestId, provider),
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      "Withdraw",
                      style: TextStyle(color: Colors.red),
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
            OutlinedButton(
              onPressed: () => _showRejectDialog(req.requestId, provider),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Decline"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () =>
                  _handleAction(provider.acceptCompanyInvite(req.requestId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Accept"),
            ),
          ];
        }
        return _buildRequestCard(req, actions: actions, isReceived: true);
      },
    );

    return isMobile ? RefreshIndicator(onRefresh: _refresh, child: list) : list;
  }

  // --- Card Components ---

  Widget _buildRequestCard(
    InterviewRequest req, {
    List<Widget>? actions,
    bool isReceived = false,
  }) {
    final dateStr = DateFormat('MMM d, yyyy').format(req.requestDate);
    final String? logoUrl = (req.logoUrl != null && req.logoUrl!.isNotEmpty)
        ? (req.logoUrl!.startsWith('http')
              ? req.logoUrl
              : "$_serverBaseUrl${req.logoUrl}")
        : null;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo with Beautiful Fallback
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
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
                  const SizedBox(width: 16),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.companyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        if (req.industry != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            req.industry!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  _buildStatusBadge(req.status),
                ],
              ),
              if (actions != null && actions.isNotEmpty) ...[
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
              if (req.status == RequestStatus.Rejected &&
                  req.reasonForReject != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Reason: ${req.reasonForReject}",
                          style: TextStyle(
                            color: Colors.red.shade700,
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
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Icon(Icons.business, color: Colors.grey.shade400, size: 28),
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
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
        color = Colors.red;
        text = "Rejected";
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.orange;
        text = "Pending";
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
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

  // 🔹 WEB HEADER (Top Navigation Bar)
  Widget _buildWebHeader(
    BuildContext context,
    dynamic student,
    String? profileImageUrl,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 80,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/StudentJobFairPortalLogo.png',
                  height: 35,
                ),
                const SizedBox(width: 12),
                Text(
                  "COMSATS Job Fair",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                ..._sidebarItems.map((item) {
                  final isSelected = item.text == 'Requests';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: TextButton.icon(
                          onPressed: () async {
                            if (_implementedRoutes.contains(item.text)) {
                              item.onPressed();

                              if (item.text == 'Profile') {
                                Navigator.pushReplacement(
                                  context,
                                  FadePageRoute(page: const ProfileScreen()),
                                );
                              } else if (item.text == 'Companies') {
                                Navigator.pushReplacement(
                                  context,
                                  FadePageRoute(page: const CompaniesScreen()),
                                );
                              } else if (item.text == 'Jobs') {
                                Navigator.pushReplacement(
                                  context,
                                  FadePageRoute(page: const JobsScreen()),
                                );
                              } else if (item.text == 'Requests') {
                                // Already here
                              }
                            } else if (item.text == 'Logout') {
                              item.onPressed();
                              await Provider.of<StudentProvider>(
                                context,
                                listen: false,
                              ).logout();
                              if (mounted) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${item.text} is coming soon!"),
                                ),
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: isSelected
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.15)
                                : Colors.transparent,
                            foregroundColor: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(item.icon, size: 20),
                          label: Text(
                            item.text,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(width: 20),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null
                      ? Text(
                          (student?.user.fullName ?? "U")[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
