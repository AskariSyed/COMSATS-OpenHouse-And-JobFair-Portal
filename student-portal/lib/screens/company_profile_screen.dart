import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

// Providers & Models
import 'package:student_job_fair_portal/provider/company_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/model/company.dart';
import 'package:student_job_fair_portal/model/job.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'package:student_job_fair_portal/config/backend_config.dart';

class CompanyProfileScreen extends StatefulWidget {
  final int companyId;
  final String companyName;

  const CompanyProfileScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final String _serverBaseUrl = BackendConfig.serverBaseUrl;
  bool _isSendingRequest = false; // Loading state for request button
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanyDetails();
    });
  }

  Future<void> _loadCompanyDetails() async {
    final studentToken = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).token;
    if (studentToken != null) {
      await Provider.of<CompanyProvider>(
        context,
        listen: false,
      ).fetchCompanyDetails(widget.companyId, studentToken, forceRefresh: true);
    }
  }

  // --- Actions ---

  Future<void> _handleSendInterviewRequest() async {
    final company = Provider.of<CompanyProvider>(
      context,
      listen: false,
    ).selectedCompany;
    if (company != null && !company.isInterviewWindowOpen) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Job Fair has ended."),
      );
      return;
    }

    setState(() => _isSendingRequest = true);

    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final errorMessage = await studentProvider.sendInterviewRequest(
      widget.companyId,
    );

    if (!mounted) return;
    setState(() => _isSendingRequest = false);

    if (errorMessage == null) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(
          message: "Interview request sent successfully!",
        ),
      );
      _loadCompanyDetails(); // Refresh to update UI to "Pending"
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: errorMessage),
      );
    }
  }

  Future<void> _handleAcceptInvite(int requestId) async {
    final company = Provider.of<CompanyProvider>(
      context,
      listen: false,
    ).selectedCompany;
    if (company != null && !company.isInterviewWindowOpen) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Job Fair has ended."),
      );
      return;
    }

    setState(() => _isSendingRequest = true);
    final provider = Provider.of<StudentProvider>(context, listen: false);
    final error = await provider.acceptCompanyInvite(requestId);

    if (!mounted) return;
    setState(() => _isSendingRequest = false);

    if (error == null) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(message: "Interview Accepted!"),
      );
      _loadCompanyDetails();
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: error),
      );
    }
  }

  Future<void> _handleRejectInvite(int requestId) async {
    // Show confirmation dialog first
    final reasonCtrl = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Decline Invitation"),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: "Reason (Optional)",
            hintText: "e.g. Not interested",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Decline", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldReject != true) return;

    setState(() => _isSendingRequest = true);
    final provider = Provider.of<StudentProvider>(context, listen: false);
    final error = await provider.rejectCompanyInvite(
      requestId,
      reasonCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSendingRequest = false);

    if (error == null) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: "Invitation Declined."),
      );
      _loadCompanyDetails();
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;
    final company = companyProvider.selectedCompany;
    final isLoading = companyProvider.isLoading;

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

        // ---------------- MOBILE LAYOUT ----------------
        if (isMobile) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/LogoWithoutBg.png',
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.companyName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).cardColor,
              elevation: 0,
              iconTheme: IconThemeData(
                color: Theme.of(context).iconTheme.color,
              ),
              centerTitle: true,
            ),
            body: isLoading
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildShimmerContent(context),
                  )
                : company == null
                ? _buildErrorState(companyProvider)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(company),
                  ),
          );
        }

        // ---------------- WEB LAYOUT ----------------
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
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 30,
                            ),
                            child: isLoading
                                ? _buildShimmerContent(context)
                                : company == null
                                ? _buildErrorState(companyProvider)
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        child: InkWell(
                                          onTap: () => Navigator.pop(context),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.arrow_back_ios_new,
                                                size: 16,
                                                color: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.color,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Back to Companies",
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall?.color,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      _buildContent(company),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      const WebFooter(),
                    ],
                  ),
                ),
              ),
              BeautifulWebNavBar(
                currentRoute: 'Companies', // or 'Jobs', 'Companies', etc.
                profileImageUrl: profileImageUrl,
                userName: student?.user.fullName ?? "User",
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Content Builder ---

  Widget _buildContent(CompanyDetail company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(company),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) {
            return constraints.maxWidth > 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildJobsSection(company),
                            const SizedBox(height: 30),
                            _buildSkillsSection(company),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildInfoCard(company),
                            const SizedBox(height: 20),
                            _buildContactCard(company),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildInfoCard(company),
                      const SizedBox(height: 20),
                      _buildContactCard(company),
                      const SizedBox(height: 30),
                      _buildSkillsSection(company),
                      const SizedBox(height: 30),
                      _buildJobsSection(company),
                    ],
                  );
          },
        ),
      ],
    );
  }

  // --- Hero Card with Smart Action Button ---

  Widget _buildHeroCard(CompanyDetail company) {
    final String? logoUrl =
        (company.logoUrl != null && company.logoUrl!.isNotEmpty)
        ? (company.logoUrl!.startsWith('http')
              ? company.logoUrl
              : "$_serverBaseUrl${company.logoUrl}")
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade100,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) =>
                                _buildFallbackIcon(),
                          )
                        : _buildFallbackIcon(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (company.industry != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.blue.shade900.withValues(alpha: 0.3)
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            company.industry!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (company.description != null) ...[
              InkWell(
                onTap: () => setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.description!,
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow: _isDescriptionExpanded
                          ? null
                          : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.6,
                      ),
                    ),
                    if (company.description!.length > 100)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _isDescriptionExpanded ? "Show Less" : "Read More",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 🎯 SMART ACTION SECTION
            _buildActionSection(company),
          ],
        ),
      ),
    );
  }

  // --- Logic for Request Button vs Status Card ---

  Widget _buildActionSection(CompanyDetail company) {
    if (!company.isInterviewWindowOpen) {
      return _buildStatusCard(
        color: Colors.red,
        icon: Icons.event_busy,
        title: "Job Fair Closed",
        subtitle: "Job Fair has ended.",
      );
    }

    final req = company.interviewRequest;
    final requestStatus = req?.status.toLowerCase() ?? '';
    final requestedBy = req?.requestedBy.toLowerCase() ?? '';
    final interviewStatus =
        (company.latestInterview?.status ?? req?.currentInterviewStatus ?? '')
            .toLowerCase();
    final scheduledTime =
        company.latestInterview?.scheduledTime ?? req?.interviewScheduledTime;
    final interviewRoom =
        company.latestInterview?.room ?? req?.interviewRoom ?? 'TBA';
    final scheduledDisplay = scheduledTime != null
        ? '${scheduledTime.toLocal().day.toString().padLeft(2, '0')}-${scheduledTime.toLocal().month.toString().padLeft(2, '0')}-${scheduledTime.toLocal().year} ${scheduledTime.toLocal().hour.toString().padLeft(2, '0')}:${scheduledTime.toLocal().minute.toString().padLeft(2, '0')}'
        : null;

    if (requestStatus == 'pending') {
      // 1. PENDING REQUEST
      if (requestedBy == 'company') {
        // A. Invited by Company (Action needed)
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.purple.shade900.withValues(alpha: 0.3)
                : Colors.purple.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.purple.shade700 : Colors.purple.shade200,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    color: isDark
                        ? Colors.purple.shade300
                        : Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "You have been Invited!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.purple.shade200
                          : Colors.purple.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${company.name} wants to interview you.",
                style: TextStyle(color: Colors.purple.shade700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSendingRequest
                          ? null
                          : () => _handleRejectInvite(req!.requestId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Decline"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSendingRequest
                          ? null
                          : () => _handleAcceptInvite(req!.requestId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSendingRequest
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Accept Invite"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      // B. Sent by Student (Waiting)
      return _buildStatusCard(
        color: Colors.orange,
        icon: Icons.hourglass_top,
        title: "Request Sent",
        subtitle: "Waiting for company response.",
      );
    }

    if (interviewStatus == 'queued') {
      if (scheduledDisplay != null) {
        return _buildStatusCard(
          color: Colors.green,
          icon: Icons.event_available,
          title: 'Interview Scheduled',
          subtitle: 'Time: $scheduledDisplay • Room: $interviewRoom',
        );
      }

      return _buildStatusCard(
        color: Colors.blue,
        icon: Icons.schedule,
        title: "Request Accepted",
        subtitle:
            "Your request is accepted. Interview scheduling is in progress.",
      );
    }

    if (interviewStatus == 'inprogress') {
      return _buildStatusCard(
        color: Colors.deepPurple,
        icon: Icons.play_circle_outline,
        title: "Interview On-going",
        subtitle: "Your interview is currently in progress.",
      );
    }

    if (interviewStatus == 'hired') {
      return _buildStatusCard(
        color: Colors.green,
        icon: Icons.verified,
        title: "Hired",
        subtitle: "Congratulations! You have been hired.",
      );
    }

    if (interviewStatus == 'shortlisted') {
      return _buildStatusCard(
        color: Colors.teal,
        icon: Icons.stars,
        title: "Shortlisted",
        subtitle: "Great news! You are shortlisted.",
      );
    }

    if (interviewStatus == 'rejected') {
      return _buildStatusCard(
        color: Colors.red,
        icon: Icons.cancel_outlined,
        title: "Not Selected",
        subtitle: "This interview did not result in selection.",
      );
    }

    if (requestStatus == 'accepted') {
      if (scheduledDisplay != null) {
        return _buildStatusCard(
          color: Colors.green,
          icon: Icons.event_available,
          title: 'Interview Scheduled',
          subtitle: 'Time: $scheduledDisplay • Room: $interviewRoom',
        );
      }

      return _buildStatusCard(
        color: Colors.green,
        icon: Icons.check_circle_outline,
        title: "Request Accepted",
        subtitle: "Your interview request has been accepted.",
      );
    }

    if (requestStatus == 'rejected') {
      return _buildStatusCard(
        color: Colors.red,
        icon: Icons.cancel_outlined,
        title: "Request Rejected",
        subtitle: "This request was not successful.",
      );
    }

    // NO REQUEST/INTERVIEW -> SHOW BUTTON
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSendingRequest ? null : _handleSendInterviewRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSendingRequest
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Request Interview",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildStatusCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.8),
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

  // --- Other Components (Jobs, Skills, Info) ---

  Widget _buildInfoCard(CompanyDetail company) {
    return _buildCard(
      title: "Highlights",
      icon: Icons.flash_on,
      child: Column(
        children: [
          _buildHighlightRow(
            Icons.timer_outlined,
            "Interview Duration",
            "${company.interviewDurationMinutes} mins",
          ),
          const Divider(height: 24),
          _buildHighlightRow(
            Icons.groups_outlined,
            "Representatives",
            "${company.repsCount > 0 ? company.repsCount : 'N/A'} Attending",
          ),
          if (company.focalPersonName != null) ...[
            const Divider(height: 24),
            _buildHighlightRow(
              Icons.badge_outlined,
              "Focal Person",
              company.focalPersonName!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(CompanyDetail company) {
    return _buildCard(
      title: "Get in Touch",
      icon: Icons.connect_without_contact,
      child: Column(
        children: [
          if (company.website != null)
            _buildContactRow(
              Icons.language,
              "Website",
              company.website!,
              isLink: true,
            ),
          if (company.email != null)
            _buildContactRow(
              Icons.email_outlined,
              "Email",
              company.email!,
              isLink: true,
              urlPrefix: 'mailto:',
            ),
          if (company.phone != null)
            _buildContactRow(
              Icons.phone_outlined,
              "Phone",
              company.phone!,
              isLink: true,
              urlPrefix: 'tel:',
            ),
          if (company.address != null)
            _buildContactRow(
              Icons.location_on_outlined,
              "Address",
              company.address!,
            ),
          if (company.contactLinks.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Social Profiles",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: company.contactLinks
                  .map((link) => _buildSocialButton(link))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsSection(CompanyDetail company) {
    if (company.uniqueSkillsRequired.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Technology Stack",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade200,
            ),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: company.uniqueSkillsRequired.map((skill) {
              return Chip(
                label: Text(skill),
                backgroundColor: isDark
                    ? Colors.blue.shade900.withValues(alpha: 0.3)
                    : Colors.blue.shade50,
                labelStyle: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildJobsSection(CompanyDetail company) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Open Positions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blueGrey.shade900,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${company.jobs.length} Active",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (company.jobs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.work_off_outlined,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).iconTheme.color?.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "No positions listed currently",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: company.jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              final job = company.jobs[i];
              return JobCard(job: job);
            },
          ),
      ],
    );
  }

  // --- Helpers ---

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: Colors.blueGrey.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    String urlPrefix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                isLink
                    ? InkWell(
                        onTap: () => launchUrl(
                          Uri.parse("$urlPrefix$value"),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(CompanyContactLink link) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData icon;
    Color color;
    switch (link.platform.toLowerCase()) {
      case 'linkedin':
        icon = Icons.business;
        color = const Color(0xFF0077B5);
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = const Color(0xFF1877F2);
        break;
      default:
        icon = Icons.link;
        color = isDark ? Colors.grey.shade400 : Colors.grey;
    }

    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              link.platform,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Icon(Icons.business, size: 40, color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildShimmerContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CompanyProvider provider) {
    final isNotFound =
        provider.error?.toLowerCase().contains("not found") ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              provider.error ?? "Failed to load.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text("Go Back"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).cardColor,
                    foregroundColor: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                if (!isNotFound) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadCompanyDetails,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Retry"),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class JobCard extends StatefulWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final job = widget.job;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.jobTypeString,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                if (job.jobDescription != null)
                  Text(
                    job.jobDescription!,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.requiredSkills.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                if (job.jobDescription != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    job.jobDescription!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
