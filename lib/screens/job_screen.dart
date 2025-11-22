import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';

// Providers
import 'package:student_job_fair_portal/provider/job_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';

// Models
import 'package:student_job_fair_portal/model/job.dart';
import 'package:student_job_fair_portal/screens/complete_profile_screen.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/appbar.dart';
import 'package:student_job_fair_portal/widgets/build_bottom_navbar.dart';
import 'package:student_job_fair_portal/widgets/build_shimmer_grid.dart';
import 'package:student_job_fair_portal/widgets/custom_nav_bar.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';

// Screens for Navigation
import 'package:student_job_fair_portal/screens/profile.dart';
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/screens/requestScreen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final String _serverBaseUrl = "http://192.168.137.1:5158";
  late List<CollapsibleItem> _sidebarItems;
  String _currentRoute = 'Jobs';

  final List<String> _implementedRoutes = [
    'Profile',
    'Dashboard',
    'Companies',
    'Jobs',
    'Requests',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sidebarItems = generateSidebarItems(context, setState, _currentRoute);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    if (studentProvider.token != null) {
      await jobProvider.fetchJobs(studentProvider.token!);
    }
  }

  void _onSearchChanged(String query) {
    Provider.of<JobProvider>(context, listen: false).searchJobs(query);
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    final String? profileImageUrl =
        (student?.profilePicUrl != null && student!.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : _serverBaseUrl + student.profilePicUrl!)
        : null;

    final bool showShimmer =
        jobProvider.isLoading && jobProvider.displayJobs.isEmpty;
    final bool showDataWithLoading =
        jobProvider.isLoading && jobProvider.displayJobs.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        if (screenWidth < 800) {
          // --- MOBILE LAYOUT ---
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
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        showShimmer
                            ? buildShimmerGrid(isMobile: true)
                            : jobProvider.error != null &&
                                  jobProvider.displayJobs.isEmpty
                            ? SizedBox(
                                height: 400,
                                child: Center(child: Text(jobProvider.error!)),
                              )
                            : _buildJobsGrid(
                                jobProvider.displayJobs,
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
            bottomNavigationBar: buildBottomNav(context, 1),
          );
        } else {
          // --- WEB LAYOUT ---
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Available Jobs",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Colors.blueGrey.shade800,
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Explore opportunities tailored for you.",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 300,
                                        child: _buildSearchBar(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  showShimmer
                                      ? buildShimmerGrid(isMobile: false)
                                      : jobProvider.displayJobs.isEmpty
                                      ? const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Text("No jobs found."),
                                          ),
                                        )
                                      : _buildJobsGrid(
                                          jobProvider.displayJobs,
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: "Search jobs, companies, skills...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
    );
  }

  Widget _buildJobsGrid(List<Job> jobs, {required bool isMobile}) {
    if (jobs.isEmpty) return const Center(child: Text("No jobs found."));

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        int columns = 1;
        if (availableWidth > 1350)
          columns = 3;
        else if (availableWidth > 900)
          columns = 2;

        final double spacing = 16.0;
        final double totalSpacing = (columns - 1) * spacing;
        final double cardWidth = (availableWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: jobs
              .map(
                (job) => SizedBox(
                  width: columns > 1 ? cardWidth : double.infinity,
                  child: _buildJobCard(job),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildJobCard(Job job) {
    final String? logoUrl =
        (job.companyLogoUrl != null && job.companyLogoUrl!.isNotEmpty)
        ? (job.companyLogoUrl!.startsWith('http')
              ? job.companyLogoUrl
              : "$_serverBaseUrl${job.companyLogoUrl}")
        : null;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.business, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.work, color: Colors.blueGrey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.companyName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.jobTypeString,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Skills: ${job.requiredSkills.join(', ')}",
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanyProfileScreen(
                        companyId: job.companyId,
                        companyName: job.companyName,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
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
                  final isSelected = item.text == 'Jobs';
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
                                // Already here
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
