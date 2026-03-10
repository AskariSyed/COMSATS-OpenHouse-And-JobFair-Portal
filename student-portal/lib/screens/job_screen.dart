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
import 'package:student_job_fair_portal/widgets/build_shimmer_grid.dart';
import 'package:student_job_fair_portal/widgets/web_footer.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final String _serverBaseUrl = "http://192.168.137.1:5158";
  final TextEditingController _searchController = TextEditingController();
  final Set<JobType> _selectedJobTypes = {};
  String _selectedSortOption = 'Newest'; // Default sort

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

    // Filter jobs
    var filteredJobs = jobProvider.displayJobs.where((job) {
      if (_selectedJobTypes.isEmpty) return true;
      return _selectedJobTypes.contains(job.jobType);
    }).toList();

    // Sort jobs
    if (_selectedSortOption == 'Newest') {
      filteredJobs.sort((a, b) => b.jobId.compareTo(a.jobId));
    } else if (_selectedSortOption == 'Title (A-Z)') {
      filteredJobs.sort(
        (a, b) => a.jobTitle.toLowerCase().compareTo(b.jobTitle.toLowerCase()),
      );
    } else if (_selectedSortOption == 'Company (A-Z)') {
      filteredJobs.sort(
        (a, b) =>
            a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()),
      );
    }

    final bool showDataWithLoading =
        jobProvider.isLoading && jobProvider.displayJobs.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        if (screenWidth < 800) {
          // ==================================================================
          // MOBILE LAYOUT
          // ==================================================================
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            extendBody: true,
            appBar: const BeautifulAppBar(title: "Available Jobs"),
            body: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      100,
                    ), // Extra padding for bottom nav
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        showShimmer
                            ? buildShimmerGrid(isMobile: true)
                            : jobProvider.error != null &&
                                  jobProvider.displayJobs.isEmpty
                            ? SizedBox(
                                height: 100,
                                child: Center(child: Text(jobProvider.error!)),
                              )
                            : filteredJobs.isEmpty
                            ? const SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text("No jobs match your filters."),
                                ),
                              )
                            : _buildJobsGrid(filteredJobs, isMobile: true),
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
            bottomNavigationBar: const BeautifulMobileNavBar(currentIndex: 2),
          );
        } else {
          // ==================================================================
          // WEB LAYOUT
          // ==================================================================
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                                          width: 300,
                                          child: _buildSearchBar(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    showShimmer
                                        ? buildShimmerGrid(isMobile: false)
                                        : filteredJobs.isEmpty
                                        ? const SizedBox(
                                            height: 200,
                                            child: Center(
                                              child: Text("No jobs found."),
                                            ),
                                          )
                                        : _buildJobsGrid(
                                            filteredJobs,
                                            isMobile: false,
                                          ),
                                  ],
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
        }
      },
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search jobs, companies, skills...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).primaryColor,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade200,
            ),
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: _selectedJobTypes.isNotEmpty
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).iconTheme.color,
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
                      onPressed: () => Navigator.pop(context),
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
  Widget _buildJobsGrid(List<Job> jobs, {required bool isMobile}) {
    if (jobs.isEmpty) return const Center(child: Text("No jobs found."));
    final Map<int, List<Job>> groupedJobs = {};
    for (var job in jobs) {
      if (!groupedJobs.containsKey(job.companyId)) {
        groupedJobs[job.companyId] = [];
      }
      groupedJobs[job.companyId]!.add(job);
    }

    final groups = groupedJobs.values.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        int columns = 1;
        if (availableWidth > 1350) {
          columns = 3;
        } else if (availableWidth > 900)
          columns = 2;

        final double spacing = 12.0;
        final double totalSpacing = (columns - 1) * spacing;
        final double cardWidth = (availableWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: groups.map((companyJobs) {
            return SizedBox(
              width: columns > 1 ? cardWidth : double.infinity,
              child: _buildCompanyGroupCard(companyJobs),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCompanyGroupCard(List<Job> jobs) {
    if (jobs.isEmpty) return const SizedBox.shrink();

    return CompanyJobCard(jobs: jobs, serverBaseUrl: _serverBaseUrl);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String? logoUrl =
        (companyData.companyLogoUrl != null &&
            companyData.companyLogoUrl!.isNotEmpty)
        ? (companyData.companyLogoUrl!.startsWith('http')
              ? companyData.companyLogoUrl
              : "${widget.serverBaseUrl}${companyData.companyLogoUrl}")
        : null;

    final isMobile = MediaQuery.of(context).size.width < 700;
    final hasMultipleJobs = jobs.length > 1;
    return Card(
      elevation: isDark ? 4 : 6,
      shadowColor: isDark
          ? const Color.fromARGB(255, 169, 190, 207).withValues(alpha: 0.3)
          : const Color.fromARGB(255, 10, 149, 255).withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.white, Colors.blue.shade50.withValues(alpha: 0.3)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          // 🔹 ADJUSTED PADDING: reduced bottom padding to ensure it's not too spacious
          padding: EdgeInsets.only(
            left: isMobile ? 10 : 16.0,
            right: isMobile ? 10 : 16.0,
            top: isMobile ? 10 : 16.0,
            bottom: isMobile ? 8 : 8.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      width: isMobile ? 46 : 54,
                      height: isMobile ? 46 : 54,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade200,
                        ),
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
                          : const Icon(Icons.business, color: Colors.blueGrey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
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
                          const SizedBox(height: 1),
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
                  ),
                  if (hasMultipleJobs)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).primaryColor,
                      ),
                      tooltip: _isExpanded ? "Show Less" : "Show All Jobs",
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
                      Icons.arrow_forward,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withValues(alpha: 0.6),
                    ),
                    tooltip: "View Company Profile",
                  ),
                ],
              ),
              if (hasMultipleJobs || jobs.isNotEmpty) ...[
                SizedBox(height: isMobile ? 8 : 12),
                const Divider(height: 1),
                SizedBox(height: isMobile ? 8 : 12),
              ],

              ListView.separated(
                padding:
                    EdgeInsets.zero, // 🔹 FIX: Removes internal List padding
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hasMultipleJobs && !_isExpanded ? 1 : jobs.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 2),
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                        ),
                      ),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                              color: isDark
                                  ? Colors.blue.shade900.withValues(alpha: 0.3)
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job.jobTypeString,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              if (hasMultipleJobs && !_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isExpanded = true;
                        });
                      },
                      icon: Icon(
                        Icons.expand_more,
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                      label: Text(
                        '+${jobs.length - 1} more position${jobs.length - 1 == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
