import 'dart:ui'; // Required for ImageFilter
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';

import 'package:student_job_fair_portal/screens/complete_profile_screen.dart';
import 'package:student_job_fair_portal/widgets/custom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

// Providers & Models
import 'package:student_job_fair_portal/provider/company_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/model/company.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/appbar.dart';
import 'package:student_job_fair_portal/widgets/build_bottom_navbar.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';

// Screens
import 'package:student_job_fair_portal/screens/profile.dart';
import 'package:student_job_fair_portal/screens/job_screen.dart';
import 'package:student_job_fair_portal/screens/requestScreen.dart';

// Utils
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final String _serverBaseUrl = "http://192.168.137.1:5158";

  late List<CollapsibleItem> _sidebarItems;
  String _currentRoute = 'Companies';

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
    _sidebarItems = generateSidebarItems(context, setState, _currentRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final companyProvider = Provider.of<CompanyProvider>(
      context,
      listen: false,
    );

    if (studentProvider.token != null) {
      await companyProvider.fetchCompanies(studentProvider.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    final String? profileImageUrl =
        (student?.profilePicUrl != null && student!.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : _serverBaseUrl + student.profilePicUrl!)
        : null;

    final bool showShimmer =
        companyProvider.isLoading && companyProvider.companies.isEmpty;
    final bool showDataWithLoading =
        companyProvider.isLoading && companyProvider.companies.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        if (screenWidth < 800) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: buildAppBar(context, studentProvider),
            body: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        showShimmer
                            ? _buildShimmerGrid(isMobile: true)
                            : companyProvider.error != null &&
                                  companyProvider.companies.isEmpty
                            ? SizedBox(
                                height: constraints.maxHeight * 0.7,
                                child: Center(
                                  child: Text(companyProvider.error!),
                                ),
                              )
                            : _buildCompaniesGrid(
                                companyProvider.companies,
                                isMobile: true,
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                if (showDataWithLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
            bottomNavigationBar: buildBottomNav(context, 2),
          );
        } else {
          _sidebarItems = generateSidebarItems(
            context,
            setState,
            _currentRoute,
          );

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
                                    "Participating Companies",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Browse companies offering jobs at the fair.",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  showShimmer
                                      ? _buildShimmerGrid(isMobile: false)
                                      : _buildCompaniesGrid(
                                          companyProvider.companies,
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
                _buildWebHeader(context, student, profileImageUrl),
                if (showDataWithLoading)
                  const Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
          );
        }
      },
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
              color: Colors.white.withOpacity(0.7),
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
                  final isSelected = item.text == 'Companies';
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
                              } else if (item.text == 'Jobs') {
                                Navigator.pushReplacement(
                                  context,
                                  FadePageRoute(page: const JobsScreen()),
                                );
                              } else if (item.text == 'Requests') {
                                Navigator.pushReplacement(
                                  context,
                                  FadePageRoute(page: const RequestsScreen()),
                                );
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
                              showTopSnackBar(
                                Overlay.of(context),
                                CustomSnackBar.info(
                                  message: "${item.text} feature is upcoming!",
                                  backgroundColor: Colors.orange.shade400,
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

  Widget _buildShimmerGrid({required bool isMobile}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        int columns = 1;
        if (availableWidth > 1350)
          columns = 4;
        else if (availableWidth > 1000)
          columns = 3;
        else if (availableWidth > 700)
          columns = 2;

        final double spacing = 16.0;
        final double totalSpacing = (columns - 1) * spacing;
        final double cardWidth = (availableWidth - totalSpacing) / columns;

        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(8, (index) {
              return SizedBox(
                width: columns > 1 ? cardWidth : double.infinity,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildCompaniesGrid(
    List<Company> companies, {
    required bool isMobile,
  }) {
    if (companies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "No companies found.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        int columns = 1;
        if (availableWidth > 1350)
          columns = 4;
        else if (availableWidth > 1000)
          columns = 3;
        else if (availableWidth > 700)
          columns = 2;

        final double spacing = 16.0;
        final double totalSpacing = (columns - 1) * spacing;
        final double cardWidth = (availableWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: companies.map((company) {
            return SizedBox(
              width: columns > 1 ? cardWidth : double.infinity,
              child: CompanyCard(
                company: company,
                serverBaseUrl: _serverBaseUrl,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class CompanyCard extends StatefulWidget {
  final Company company;
  final String serverBaseUrl;

  const CompanyCard({
    super.key,
    required this.company,
    required this.serverBaseUrl,
  });

  @override
  State<CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard> {
  bool _isExpanded = false;

  String _getJobTypeString(int type) {
    switch (type) {
      case 0:
        return "Full Time";
      case 1:
        return "Part Time";
      case 2:
        return "Internship";
      case 3:
        return "Remote";
      case 4:
        return "Onsite";
      default:
        return "Other";
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final String? logoUrl =
        (company.logoUrl != null && company.logoUrl!.isNotEmpty)
        ? (company.logoUrl!.startsWith('http')
              ? company.logoUrl
              : "${widget.serverBaseUrl}${company.logoUrl}")
        : null;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header: Logo & Name ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.business,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.business,
                            color: Colors.blueGrey,
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (company.industry != null)
                          Text(
                            company.industry!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Rotatable Icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0, // Rotates 180 degrees
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Description (Truncated if not expanded) ---
              if (!_isExpanded && company.description != null)
                Text(
                  company.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 8),

              // --- Stats Footer (Job Count) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          size: 14,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${company.jobCount} Jobs",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  if (company.website != null)
                    Tooltip(
                      message: "Visit Website",
                      child: InkWell(
                        onTap: () => launchUrl(
                          Uri.parse(company.website!),
                          mode: LaunchMode.externalApplication,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.language,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // --- Expanded Content: Jobs List with Animation ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade200),
                          const SizedBox(height: 8),

                          // --- NEW: View Profile Button ---
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CompanyProfileScreen(
                                      companyId: company.companyId,
                                      companyName: company.name,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility, size: 18),
                              label: const Text("View Full Profile"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            "Available Positions",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          AnimatedOpacity(
                            opacity: _isExpanded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: company.jobs.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      "No jobs listed yet.",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: company.jobs.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 24,
                                      color: Colors.grey.shade100,
                                    ),
                                    itemBuilder: (context, index) {
                                      final job = company.jobs[index];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Job Header
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  job.jobTitle,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color:
                                                        Colors.green.shade100,
                                                  ),
                                                ),
                                                child: Text(
                                                  _getJobTypeString(
                                                    job.jobType.index,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.green.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          // Job Description (Short)
                                          if (job.jobDescription != null &&
                                              job.jobDescription!.isNotEmpty)
                                            Text(
                                              job.jobDescription!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),

                                          const SizedBox(height: 8),

                                          // Skills
                                          if (job
                                              .requiredSkills
                                              .isNotEmpty) ...[
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: job.requiredSkills.map((
                                                skill,
                                              ) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    skill,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
