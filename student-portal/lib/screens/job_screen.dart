import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:student_job_fair_portal/provider/job_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';

// Models
import 'package:student_job_fair_portal/model/job.dart';
import 'package:student_job_fair_portal/mixins/enums.dart';

// Screens
import 'package:student_job_fair_portal/screens/company_profile_screen.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart';
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart';
import 'package:student_job_fair_portal/widgets/app_animations.dart';
import 'package:student_job_fair_portal/widgets/build_shimmer_grid.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final String _serverBaseUrl = BackendConfig.serverBaseUrl;
  final TextEditingController _searchController = TextEditingController();
  final Set<JobType> _selectedJobTypes = {};
  String _selectedSortOption = 'Newest'; // Default sort
  static const int _jobsPerPage = 6;

  @override
  void initState() {
    super.initState();
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
      await jobProvider.fetchJobs(
        studentProvider.token!,
        page: 1,
        pageSize: _jobsPerPage,
      );
      await jobProvider.fetchRecommendedJobs(studentProvider.token!);
    }
  }

  Future<void> _loadJobsPage(int page) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    if (studentProvider.token != null) {
      await jobProvider.searchJobs(
        _searchController.text,
        token: studentProvider.token,
        jobTypes: _selectedJobTypes.toList(),
        page: page,
        pageSize: _jobsPerPage,
      );
    }
  }

  void _onSearchChanged(String query) {
    Provider.of<JobProvider>(context, listen: false).searchJobs(
      query,
      token: Provider.of<StudentProvider>(context, listen: false).token,
      jobTypes: _selectedJobTypes.toList(),
      page: 1,
      pageSize: _jobsPerPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;
    final theme = Theme.of(context);

    final String? profileImageUrl =
        (student?.profilePicUrl != null && student!.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : _serverBaseUrl + student.profilePicUrl!)
        : null;

    final bool showShimmer =
        jobProvider.isLoading && jobProvider.displayJobs.isEmpty;

    final displayJobs = List<Job>.from(jobProvider.displayJobs);

    // Sort jobs
    if (_selectedSortOption == 'Newest') {
      displayJobs.sort((a, b) => b.jobId.compareTo(a.jobId));
    } else if (_selectedSortOption == 'Title (A-Z)') {
      displayJobs.sort(
        (a, b) => a.jobTitle.toLowerCase().compareTo(b.jobTitle.toLowerCase()),
      );
    } else if (_selectedSortOption == 'Company (A-Z)') {
      displayJobs.sort(
        (a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
      );
    }

    final groupedJobs = _groupJobsByCompany(displayJobs);
    final totalPages = jobProvider.totalPages;
    final currentPage = jobProvider.currentPage;

    final bool showDataWithLoading =
        jobProvider.isLoading && jobProvider.displayJobs.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        if (screenWidth < 800) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            extendBody: true,
            appBar: const BeautifulAppBar(title: "Available Jobs"),
            body: BeautifulMobileNavBar.withSwipeNavigation(
              context: context,
              currentIndex: 2,
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: AppPageReveal(
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            const SizedBox(height: 24),
                            // ✅ RECOMMENDED JOBS SECTION (MOBILE)
                            if (jobProvider.recommendedJobs.isNotEmpty)
                              _buildRecommendedJobsSection(isMobile: true),
                            // Show divider if recommended jobs exist
                            if (jobProvider.recommendedJobs.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  "All Available Jobs",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            showShimmer
                                ? buildShimmerGrid(isMobile: true)
                                : jobProvider.error != null &&
                                      jobProvider.displayJobs.isEmpty
                                ? SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Text(jobProvider.error!),
                                    ),
                                  )
                                : displayJobs.isEmpty
                                ? const SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Text(
                                        "No jobs match your filters.",
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      _buildJobsGrid(
                                        groupedJobs,
                                        isMobile: true,
                                      ),
                                      if (totalPages > 1) ...[
                                        const SizedBox(height: 20),
                                        _buildPaginationControls(
                                          currentPage: currentPage,
                                          totalPages: totalPages,
                                          onPrevious: currentPage > 1
                                              ? () {
                                                  _loadJobsPage(
                                                    currentPage - 1,
                                                  );
                                                }
                                              : null,
                                          onNext: currentPage < totalPages
                                              ? () {
                                                  _loadJobsPage(
                                                    currentPage + 1,
                                                  );
                                                }
                                              : null,
                                        ),
                                      ],
                                    ],
                                  ),
                          ],
                        ),
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
            ),
            bottomNavigationBar: const BeautifulMobileNavBar(currentIndex: 2),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (screenWidth < 1050)
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
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge?.color,
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Explore opportunities grouped by company.",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall?.color,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: _buildSearchBar(),
                                          ),
                                        ],
                                      )
                                    else
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                    ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                "Explore opportunities grouped by company.",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            width: screenWidth > 1200
                                                ? 440
                                                : 380,
                                            child: _buildSearchBar(),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 30),
                                    // ✅ RECOMMENDED JOBS SECTION (WEB)
                                    if (jobProvider
                                        .recommendedJobs
                                        .isNotEmpty) ...[
                                      _buildRecommendedJobsSection(
                                        isMobile: false,
                                      ),
                                      const SizedBox(height: 40),
                                      Divider(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withOpacity(0.2),
                                      ),
                                      const SizedBox(height: 30),
                                      Text(
                                        "All Available Jobs",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    showShimmer
                                        ? buildShimmerGrid(isMobile: false)
                                        : displayJobs.isEmpty
                                        ? const SizedBox(
                                            height: 200,
                                            child: Center(
                                              child: Text("No jobs found."),
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildJobsGrid(
                                                groupedJobs,
                                                isMobile: false,
                                              ),
                                              if (totalPages > 1) ...[
                                                const SizedBox(height: 20),
                                                _buildPaginationControls(
                                                  currentPage: currentPage,
                                                  totalPages: totalPages,
                                                  onPrevious: currentPage > 1
                                                      ? () {
                                                          _loadJobsPage(
                                                            currentPage - 1,
                                                          );
                                                        }
                                                      : null,
                                                  onNext:
                                                      currentPage < totalPages
                                                      ? () {
                                                          _loadJobsPage(
                                                            currentPage + 1,
                                                          );
                                                        }
                                                      : null,
                                                ),
                                              ],
                                            ],
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
              BeautifulWebNavBar(
                currentRoute: 'Jobs',
                profileImageUrl: profileImageUrl,
                userName: student?.user.fullName ?? "User",
              ),
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
      },
    );
  }

  Widget _buildSearchBar() {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final theme = Theme.of(context);
    final fillColor =
        theme.inputDecorationTheme.fillColor ??
        theme.cardColor.withValues(alpha: 0.9);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: isMobile ? 48 : 44,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textAlignVertical: const TextAlignVertical(y: 0.15),
              strutStyle: const StrutStyle(
                fontSize: 14,
                height: 1.15,
                leading: 0,
                forceStrutHeight: true,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.textTheme.bodyMedium?.color,
              ),
              decoration: InputDecoration(
                hintText: "Search jobs, companies, skills...",
                hintStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                prefixIcon: Align(
                  alignment: const Alignment(0, 0.1),
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Icon(
                    Icons.search,
                    color: theme.iconTheme.color,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: isMobile ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: isMobile ? 48 : 44,
          width: isMobile ? 48 : 44,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: _selectedJobTypes.isNotEmpty
                  ? Theme.of(context).primaryColor
                  : theme.iconTheme.color,
            ),
            tooltip: "Filter & Sort Jobs",
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter & Sort",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedJobTypes.clear();
                            _selectedSortOption = 'Newest';
                          });
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text("Clear All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Sort By",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Newest', 'Title (A-Z)', 'Company (A-Z)'].map((
                      option,
                    ) {
                      final isSelected = _selectedSortOption == option;
                      return ChoiceChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _selectedSortOption = option;
                            });
                            setState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Job Type",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: JobType.values.map((type) {
                      final isSelected = _selectedJobTypes.contains(type);
                      return FilterChip(
                        label: Text(_getJobTypeString(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedJobTypes.add(type);
                            } else {
                              _selectedJobTypes.remove(type);
                            }
                          });
                          setState(() {}); // Update parent screen
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _onSearchChanged(_searchController.text);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Apply"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getJobTypeString(JobType type) {
    switch (type) {
      case JobType.fullTime:
        return "Full Time";
      case JobType.partTime:
        return "Part Time";
      case JobType.internship:
        return "Internship";
      case JobType.remote:
        return "Remote";
      case JobType.onsite:
        return "Onsite";
      default:
        return "Other";
    }
  }

  // Grouping Logic
  List<List<Job>> _groupJobsByCompany(List<Job> jobs) {
    final Map<int, List<Job>> groupedJobs = {};
    for (final job in jobs) {
      groupedJobs.putIfAbsent(job.companyId, () => []).add(job);
    }

    return groupedJobs.values.toList();
  }

  Widget _buildJobsGrid(List<List<Job>> groups, {required bool isMobile}) {
    if (groups.isEmpty) return const Center(child: Text("No jobs found."));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildCompanyGroupCard(groups[index]);
      },
    );
  }

  Widget _buildPaginationControls({
    required int currentPage,
    required int totalPages,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Page $currentPage of $totalPages",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: Text(isMobile ? "Prev" : "Previous"),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              label: const Text("Next"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyGroupCard(List<Job> jobs) {
    if (jobs.isEmpty) return const SizedBox.shrink();

    return CompanyJobCard(jobs: jobs, serverBaseUrl: _serverBaseUrl);
  }

  Widget _buildRecommendedJobsSection({required bool isMobile}) {
    final jobProvider = Provider.of<JobProvider>(context);
    final recommendedJobs = jobProvider.recommendedJobs;
    final theme = Theme.of(context);

    if (recommendedJobs.isEmpty || jobProvider.isLoadingRecommended) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
            const SizedBox(width: 10),
            Text(
              "Recommended For You",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final double cardWidth = isMobile
                ? availableWidth * 0.82
                : availableWidth > 1200
                ? availableWidth * 0.34
                : availableWidth * 0.46;

            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recommendedJobs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildRecommendedJobCard(recommendedJobs[index]),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedJobCard(dynamic jobData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final jobTitle = jobData['jobTitle'] ?? 'Unknown Job';
    final companyName = jobData['companyName'] ?? 'Unknown Company';
    final int? companyId = int.tryParse(jobData['companyId']?.toString() ?? '');
    final companyLogo = jobData['companyLogo'];
    final matchCount = jobData['matchCount'] ?? 0;
    final matchedSkills = jobData['matchedSkills'] as List<dynamic>? ?? [];
    final jobTypeLabel = _getRecommendedJobTypeLabel(jobData['jobType']);
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    final logoUrl = companyLogo != null && companyLogo.isNotEmpty
        ? (companyLogo.startsWith('http')
              ? companyLogo
              : BackendConfig.absoluteUrl(companyLogo))
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: companyId == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyProfileScreen(
                      companyId: companyId,
                      companyName: companyName,
                    ),
                  ),
                );
              },
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: logoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.business),
                              ),
                            )
                          : const Icon(Icons.business),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            companyName,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color,
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
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Matched $matchCount',
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    SoftTag(
                      label: jobTypeLabel,
                      background: colorScheme.primary.withValues(alpha: 0.12),
                      textColor: colorScheme.primary,
                    ),
                  ],
                ),
                if (matchedSkills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: matchedSkills.take(isMobile ? 3 : 4).map((skill) {
                      return SoftTag(
                        label: skill.toString(),
                        background: theme.scaffoldBackgroundColor,
                        textColor: theme.textTheme.bodySmall?.color,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRecommendedJobTypeLabel(dynamic jobTypeValue) {
    if (jobTypeValue is int &&
        jobTypeValue >= 0 &&
        jobTypeValue < JobType.values.length) {
      return _getJobTypeString(JobType.values[jobTypeValue]);
    }

    if (jobTypeValue is String) {
      switch (jobTypeValue.toLowerCase()) {
        case '0':
        case 'fulltime':
        case 'full_time':
        case 'full time':
          return 'Full Time';
        case '1':
        case 'parttime':
        case 'part_time':
        case 'part time':
          return 'Part Time';
        case '2':
        case 'internship':
          return 'Internship';
        case '3':
        case 'remote':
          return 'Remote';
        case '4':
        case 'onsite':
        case 'on_site':
        case 'on site':
          return 'Onsite';
        default:
          return 'Other';
      }
    }

    return 'Other';
  }
}

class CompanyJobCard extends StatefulWidget {
  final List<Job> jobs;
  final String serverBaseUrl;

  const CompanyJobCard({
    super.key,
    required this.jobs,
    required this.serverBaseUrl,
  });

  @override
  State<CompanyJobCard> createState() => _CompanyJobCardState();
}

class _CompanyJobCardState extends State<CompanyJobCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final jobs = widget.jobs;
    final companyData = jobs.first;
    final String? logoUrl =
        (companyData.companyLogoUrl != null &&
            companyData.companyLogoUrl!.isNotEmpty)
        ? (companyData.companyLogoUrl!.startsWith('http')
              ? companyData.companyLogoUrl
              : "${widget.serverBaseUrl}${companyData.companyLogoUrl}")
        : null;

    final isMobile = MediaQuery.of(context).size.width < 700;
    final hasMultipleJobs = jobs.length > 1;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompanyProfileScreen(
                          companyId: companyData.companyId,
                          companyName: companyData.companyName,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: isMobile ? 44 : 52,
                    height: isMobile ? 44 : 52,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.business,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.business,
                            color: theme.iconTheme.color,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyData.companyName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${jobs.length} Open Position${jobs.length == 1 ? '' : 's'}",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompanyProfileScreen(
                          companyId: companyData.companyId,
                          companyName: companyData.companyName,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: theme.iconTheme.color,
                  ),
                  tooltip: "View Company Profile",
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: theme.dividerColor, height: 1),
            const SizedBox(height: 10),
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hasMultipleJobs && !_isExpanded ? 1 : jobs.length,
              separatorBuilder: (ctx, i) =>
                  Divider(color: theme.dividerColor.withValues(alpha: 0.5), height: 14),
              itemBuilder: (ctx, index) {
                final job = jobs[index];
                return InkWell(
                  onTap: () {
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
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.jobTitle,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (job.requiredSkills.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    job.requiredSkills.take(3).join(", ") +
                                        (job.requiredSkills.length > 3
                                            ? "..."
                                            : ""),
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SoftTag(label: job.jobTypeString),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (hasMultipleJobs && !_isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        '↓ +${jobs.length - 1} more position${jobs.length - 1 == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SoftTag extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? textColor;

  const SoftTag({
    super.key,
    required this.label,
    this.background,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color resolvedBackground =
        background ?? theme.colorScheme.primary.withValues(alpha: 0.12);
    final Color resolvedText = textColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: resolvedText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
