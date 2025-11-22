import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:student_job_fair_portal/provider/company_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/model/company.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:shimmer/shimmer.dart'; // Added Shimmer package

// Navigation targets
import 'package:student_job_fair_portal/screens/profile.dart';
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/screens/job_screen.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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
  final String _serverBaseUrl = "http://192.168.137.1:5158";
  late List<CollapsibleItem> _sidebarItems;

  // Local state for request button loading
  bool _isSendingRequest = false;

  final List<String> _implementedRoutes = [
    'Profile',
    'Dashboard',
    'Companies',
    'Jobs',
  ];

  @override
  void initState() {
    super.initState();
    _sidebarItems = generateSidebarItems(context, setState, 'Companies');
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
      ).fetchCompanyDetails(widget.companyId, studentToken);
    }
  }

  Future<void> _handleSendInterviewRequest() async {
    setState(() {
      _isSendingRequest = true;
    });

    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final errorMessage = await studentProvider.sendInterviewRequest(
      widget.companyId,
    );

    if (!mounted) return;

    setState(() {
      _isSendingRequest = false;
    });

    if (errorMessage == null) {
      // Success
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(
          message: "Interview request sent successfully!",
        ),
      );
    } else {
      // Error (e.g., already pending)
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: errorMessage),
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

        if (isMobile) {
          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: Text(
                widget.companyName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
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

        // --- WEB LAYOUT ---
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
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
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Back to Companies",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
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
              _buildWebHeader(context, student, profileImageUrl),
            ],
          ),
        );
      },
    );
  }

  // --- Shimmer Loading Widget ---
  Widget _buildShimmerContent(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Card Shimmer
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 30),

          // Split Layout Shimmer
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Jobs + Skills)
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Fake Job Cards
                          for (int i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    // Right Column (Info Cards)
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile Stack
                return Column(
                  children: [
                    // Info Cards
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Fake Jobs
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CompanyProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.domain_disabled, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            provider.error ?? "Unable to load company details",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadCompanyDetails,
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildHeroCard(CompanyDetail company) {
    final String? logoUrl =
        (company.logoUrl != null && company.logoUrl!.isNotEmpty)
        ? (company.logoUrl!.startsWith('http')
              ? company.logoUrl
              : "$_serverBaseUrl${company.logoUrl}")
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (company.industry != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                company.industry!,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: company.isPresent
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: company.isPresent
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  company.isPresent
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                  size: 16,
                                  color: company.isPresent
                                      ? Colors.green.shade700
                                      : Colors.orange.shade800,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  company.isPresent ? "On-Spot" : "Registered",
                                  style: TextStyle(
                                    color: company.isPresent
                                        ? Colors.green.shade700
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            if (company.description != null &&
                company.description!.isNotEmpty) ...[
              Text(
                company.description!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- REQUEST INTERVIEW BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSendingRequest
                    ? null
                    : _handleSendInterviewRequest,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
            const Text(
              "Social Profiles",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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

  Widget _buildSocialButton(CompanyContactLink link) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getPlatformIcon(link.platform),
            const SizedBox(width: 8),
            Text(
              link.platform,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsSection(CompanyDetail company) {
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
                color: Colors.blueGrey.shade900,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.work_off_outlined,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "No positions listed currently",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
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
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  job.jobTypeString,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Future: Navigate to job application if separate
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text("View Details"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // --- Positions & Description ---
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${job.numberOfJobs} ${job.numberOfJobs == 1 ? 'Position' : 'Positions'} Available",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (job.jobDescription != null)
                        Text(
                          job.jobDescription!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: job.requiredSkills
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSkillsSection(CompanyDetail company) {
    if (company.uniqueSkillsRequired.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Technology Stack",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: company.uniqueSkillsRequired.map((skill) {
              return Chip(
                label: Text(skill),
                backgroundColor: Colors.blue.shade50,
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    color: Colors.blueGrey.shade900,
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
    return Row(
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                  final isSelected = item.text == 'Companies';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: TextButton.icon(
                      onPressed: () {
                        if (_implementedRoutes.contains(item.text)) {
                          if (item.text == 'Profile')
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          else if (item.text == 'Companies')
                            Navigator.pop(context);
                          else if (item.text == 'Jobs')
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JobsScreen(),
                              ),
                            );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                        backgroundColor: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(item.icon, size: 18),
                      label: Text(
                        item.text,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(width: 20),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
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

  Widget _getPlatformIcon(String platform) {
    IconData icon;
    Color color;
    switch (platform.toLowerCase()) {
      case 'linkedin':
        icon = Icons.business;
        color = const Color(0xFF0077B5);
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = const Color(0xFF1877F2);
        break;
      case 'twitter':
        icon = Icons.chat_bubble;
        color = const Color(0xFF1DA1F2);
        break;
      case 'github':
        icon = Icons.code;
        color = Colors.black87;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        color = const Color(0xFFE1306C);
        break;
      default:
        icon = Icons.link;
        color = Colors.grey;
        break;
    }
    return Icon(icon, size: 18, color: color);
  }
}
