import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/screens/company_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

// Providers & Models
import 'package:student_job_fair_portal/provider/company_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart'; // 🔹 Theme
import 'package:student_job_fair_portal/model/company.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';

// Screens

// Widgets
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/web_footer.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  static const String _companyTabAll = 'all';
  static const String _companyTabWalkIn = 'walkin';

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIndustries = {};
  bool _showOnlyHiring = false;
  String _selectedSortOption = 'Name (A-Z)'; // Default sort
  String _selectedCompanyTab = _companyTabAll;
  static const int _companiesPerPage = 8;

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
    final companyProvider = Provider.of<CompanyProvider>(
      context,
      listen: false,
    );

    if (studentProvider.token != null) {
      if (studentProvider.dashboardData == null) {
        await studentProvider.fetchDashboardData();
      }
      await companyProvider.fetchCompanies(
        studentProvider.token!,
        page: 1,
        pageSize: _companiesPerPage,
      );
      await companyProvider.fetchRecommendedCompanies(studentProvider.token!);
    }
  }

  Future<void> _loadCompaniesPage(int page) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final companyProvider = Provider.of<CompanyProvider>(
      context,
      listen: false,
    );

    if (studentProvider.token != null) {
      await companyProvider.searchCompanies(
        _searchController.text,
        studentProvider.student?.skills ?? [],
        token: studentProvider.token,
        industries: _selectedIndustries.toList(),
        onlyHiring: _showOnlyHiring,
        page: page,
        pageSize: _companiesPerPage,
      );
    }
  }

  void _onSearchChanged(String query) {
    final studentSkills =
        Provider.of<StudentProvider>(context, listen: false).student?.skills ??
        [];
    Provider.of<CompanyProvider>(context, listen: false).searchCompanies(
      query,
      studentSkills,
      token: Provider.of<StudentProvider>(context, listen: false).token,
      industries: _selectedIndustries.toList(),
      onlyHiring: _showOnlyHiring,
      page: 1,
      pageSize: _companiesPerPage,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    // 🔹 Theme Colors
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    final String? profileImageUrl =
        (student?.profilePicUrl != null && student!.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : BackendConfig.absoluteUrl(student.profilePicUrl))
        : null;

    final bool showShimmer =
        companyProvider.isLoading && companyProvider.companies.isEmpty;

    final displayCompanies = List<Company>.from(companyProvider.companies);

    // Sort companies
    if (_selectedSortOption == 'Name (A-Z)') {
      displayCompanies.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (_selectedSortOption == 'Name (Z-A)') {
      displayCompanies.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
    } else if (_selectedSortOption == 'Most Openings') {
      displayCompanies.sort((a, b) => b.jobCount.compareTo(a.jobCount));
    }

    final marketOverview = studentProvider.dashboardData?.marketOverview;
    final fairDate = marketOverview?.currentFairDate;
    final isJobFairDay =
        fairDate != null && _isSameDay(fairDate, DateTime.now());
    final walkInCompanies = displayCompanies
        .where((company) => company.isWalkInInterviewing)
        .toList();
    final showWalkInTab = isJobFairDay && walkInCompanies.isNotEmpty;
    final isWalkInTabSelected =
        showWalkInTab && _selectedCompanyTab == _companyTabWalkIn;
    final companiesToDisplay = isWalkInTabSelected
        ? walkInCompanies
        : displayCompanies;

    final totalPages = companyProvider.totalPages;
    final currentPage = companyProvider.currentPage;

    final bool showDataWithLoading =
        companyProvider.isLoading && companyProvider.companies.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        if (screenWidth < 800) {
          // ==================================================================
          // MOBILE LAYOUT (Themed)
          // ==================================================================
          return Scaffold(
            backgroundColor: scaffoldBg, // 🔹 Theme
            extendBody: true,
            appBar: const BeautifulAppBar(title: "Participating Companies"),
            body: BeautifulMobileNavBar.withSwipeNavigation(
              context: context,
              currentIndex: 3,
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Column(
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          if (!isWalkInTabSelected &&
                              companyProvider.recommendedCompanies.isNotEmpty)
                            _buildRecommendedCompaniesSection(isMobile: true),
                          if (!isWalkInTabSelected &&
                              companyProvider.recommendedCompanies.isNotEmpty)
                            Divider(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.3),
                              thickness: 2,
                              height: 24,
                            ),
                          _buildCompanyTabs(
                            showWalkInTab: showWalkInTab,
                            walkInCount: walkInCompanies.length,
                          ),
                          const SizedBox(height: 8),
                          showShimmer
                              ? _buildShimmerGrid(isMobile: true)
                              : companyProvider.error != null &&
                                    companyProvider.companies.isEmpty
                              ? SizedBox(
                                  height: constraints.maxHeight * 0.7,
                                  child: Center(
                                    child: Text(
                                      companyProvider.error!,
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                )
                              : companiesToDisplay.isEmpty
                              ? SizedBox(
                                  height: constraints.maxHeight * 0.7,
                                  child: Center(
                                    child: Text(
                                      isWalkInTabSelected
                                          ? "No companies are currently available for walk-in interviews."
                                          : "No companies match your filters.",
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    _buildCompaniesGrid(
                                      companiesToDisplay,
                                      student?.skills ?? [],
                                      isMobile: true,
                                    ),
                                    if (totalPages > 1) ...[
                                      const SizedBox(height: 20),
                                      _buildPaginationControls(
                                        currentPage: currentPage,
                                        totalPages: totalPages,
                                        onPrevious: currentPage > 1
                                            ? () {
                                                _loadCompaniesPage(
                                                  currentPage - 1,
                                                );
                                              }
                                            : null,
                                        onNext: currentPage < totalPages
                                            ? () {
                                                _loadCompaniesPage(
                                                  currentPage + 1,
                                                );
                                              }
                                            : null,
                                      ),
                                    ],
                                  ],
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
            ),
            bottomNavigationBar: const BeautifulMobileNavBar(currentIndex: 3),
          );
        } else {
          // ==================================================================
          // WEB LAYOUT (Themed)
          // ==================================================================
          return Scaffold(
            backgroundColor: scaffoldBg, // 🔹 Theme
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
                                    if (screenWidth < 1050)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Participating Companies",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Browse companies offering jobs at the fair.",
                                            style: TextStyle(
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
                                                "Participating Companies",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                "Browse companies offering jobs at the fair.",
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall?.color,
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
                                    if (!isWalkInTabSelected &&
                                        companyProvider
                                            .recommendedCompanies
                                            .isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildRecommendedCompaniesSection(
                                            isMobile: false,
                                          ),
                                          const SizedBox(height: 30),
                                          Divider(
                                            color: Theme.of(
                                              context,
                                            ).dividerColor.withOpacity(0.3),
                                            thickness: 2,
                                          ),
                                          const SizedBox(height: 30),
                                          Text(
                                            "All Companies",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      ),
                                    _buildCompanyTabs(
                                      showWalkInTab: showWalkInTab,
                                      walkInCount: walkInCompanies.length,
                                    ),
                                    const SizedBox(height: 20),
                                    showShimmer
                                        ? _buildShimmerGrid(isMobile: false)
                                        : companiesToDisplay.isEmpty
                                        ? const SizedBox(
                                            height: 200,
                                            child: Center(
                                              child: Text(
                                                "No companies found.",
                                              ),
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildCompaniesGrid(
                                                companiesToDisplay,
                                                student?.skills ?? [],
                                                isMobile: false,
                                              ),
                                              if (totalPages > 1) ...[
                                                const SizedBox(height: 20),
                                                _buildPaginationControls(
                                                  currentPage: currentPage,
                                                  totalPages: totalPages,
                                                  onPrevious: currentPage > 1
                                                      ? () {
                                                          _loadCompaniesPage(
                                                            currentPage - 1,
                                                          );
                                                        }
                                                      : null,
                                                  onNext:
                                                      currentPage < totalPages
                                                      ? () {
                                                          _loadCompaniesPage(
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
                          const WebFooter(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 🔹 Beautiful Web Navigation Bar
                BeautifulWebNavBar(
                  currentRoute: 'Companies',
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
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: isMobile ? 48 : 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: "Search company name, industry...",
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
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
                    color: Colors.grey.shade600,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: (_selectedIndustries.isNotEmpty || _showOnlyHiring)
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade700,
            ),
            tooltip: "Filter Companies",
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyTabs({
    required bool showWalkInTab,
    required int walkInCount,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All Companies'),
            selected: _selectedCompanyTab == _companyTabAll || !showWalkInTab,
            onSelected: (_) {
              setState(() {
                _selectedCompanyTab = _companyTabAll;
              });
            },
          ),
          if (showWalkInTab)
            ChoiceChip(
              label: Text('Walk-In Interviewing ($walkInCount)'),
              selected: _selectedCompanyTab == _companyTabWalkIn,
              onSelected: (_) {
                setState(() {
                  _selectedCompanyTab = _companyTabWalkIn;
                });
              },
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final companies = Provider.of<CompanyProvider>(
      context,
      listen: false,
    ).companies;
    final industries = companies
        .map((c) => c.industry)
        .where((i) => i != null && i.isNotEmpty)
        .toSet()
        .toList();
    industries.sort();

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
                        "Filter Companies",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedIndustries.clear();
                            _showOnlyHiring = false;
                            _selectedSortOption = 'Name (A-Z)';
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
                    children: ['Name (A-Z)', 'Name (Z-A)', 'Most Openings'].map(
                      (option) {
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
                      },
                    ).toList(),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text("Only Hiring Companies"),
                    subtitle: const Text("Show companies with open jobs"),
                    value: _showOnlyHiring,
                    onChanged: (val) {
                      setModalState(() {
                        _showOnlyHiring = val;
                      });
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  if (industries.isNotEmpty) ...[
                    Text(
                      "Industry",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: industries.map((industry) {
                        final isSelected = _selectedIndustries.contains(
                          industry,
                        );
                        return FilterChip(
                          label: Text(industry!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedIndustries.add(industry);
                              } else {
                                _selectedIndustries.remove(industry);
                              }
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
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
                      child: const Text("Apply Filters"),
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

  // --- Grid Components ---

  Widget _buildShimmerGrid({required bool isMobile}) {
    // 🔹 Theme-Aware Shimmer
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final cardColor = Theme.of(context).cardColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        int columns = 1;
        if (availableWidth > 1350) {
          columns = 4;
        } else if (availableWidth > 1000) {
          columns = 3;
        } else if (availableWidth > 700) {
          columns = 2;
        }

        final double spacing = 16.0;
        final double totalSpacing = (columns - 1) * spacing;
        final double cardWidth = (availableWidth - totalSpacing) / columns;

        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(8, (index) {
              return SizedBox(
                width: columns > 1 ? cardWidth : double.infinity,
                child: Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(height: 200),
                ),
              );
            }),
          ),
        );
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

  // ✅ NEW: Build recommended companies section
  Widget _buildRecommendedCompaniesSection({required bool isMobile}) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final recommendedCompanies = companyProvider.recommendedCompanies;

    if (recommendedCompanies.isEmpty || companyProvider.isLoadingRecommended) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
            const SizedBox(width: 10),
            Text(
              "Recommended For You",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Recommended companies list
        LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final double cardWidth = isMobile
                ? availableWidth * 0.86
                : availableWidth > 1200
                ? availableWidth * 0.34
                : availableWidth * 0.46;

            return SizedBox(
              height: isMobile ? 170 : 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recommendedCompanies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildRecommendedCompanyCard(
                      recommendedCompanies[index],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ✅ NEW: Build individual recommended company card
  Widget _buildRecommendedCompanyCard(dynamic companyData) {
    final companyName = companyData['name'] ?? 'Unknown Company';
    final companyLogo = companyData['logoUrl'];
    final industry = companyData['industry'] ?? 'N/A';
    final jobCount = companyData['jobCount'] ?? companyData['openJobs'] ?? 0;
    final openPositions = companyData['openPositions'] ?? jobCount;
    final matchCount = companyData['matchCount'] ?? 0;
    final matchedSkills = companyData['matchedSkills'] as List<dynamic>? ?? [];

    final logoUrl = companyLogo != null && companyLogo.isNotEmpty
        ? (companyLogo.startsWith('http')
              ? companyLogo
              : BackendConfig.absoluteUrl(companyLogo))
        : null;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to company profile if companyId is available
          if (companyData['companyId'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompanyProfileScreen(
                  companyId: companyData['companyId'],
                  companyName: companyName,
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company logo & match badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            industry,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
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
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Matched $matchCount',
                            style: TextStyle(
                              color: Colors.green.shade800,
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
                    _buildSoftTag(
                      '$jobCount Open Position${jobCount != 1 ? 's' : ''}',
                      background: Colors.blue.shade50,
                      textColor: Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$jobCount Job Post${jobCount != 1 ? 's' : ''} • $openPositions Total Position${openPositions != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (matchedSkills.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: matchedSkills.take(3).map((skill) {
                        return _buildSoftTag(
                          skill.toString(),
                          background: Colors.grey.shade100,
                          textColor: Colors.grey.shade700,
                        );
                      }).toList(),
                    ),
                  ),
                if (matchedSkills.length <= 2 && matchedSkills.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: matchedSkills.map((skill) {
                        return _buildSoftTag(
                          skill.toString(),
                          background: Colors.grey.shade100,
                          textColor: Colors.grey.shade700,
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoftTag(String label, {Color? background, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: textColor ?? Colors.blue.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompaniesGrid(
    List<Company> companies,
    List<String> studentSkills, {
    required bool isMobile,
  }) {
    if (companies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No companies found.",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        int columns = 1;
        if (availableWidth > 1350) {
          columns = 4;
        } else if (availableWidth > 1000) {
          columns = 3;
        } else if (availableWidth > 700) {
          columns = 2;
        }
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
                studentSkills: studentSkills,
                serverBaseUrl: BackendConfig.serverBaseUrl,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------------
// Company Card Widget (Updated with Theme)
// ----------------------------------------------------------------------------
class CompanyCard extends StatefulWidget {
  final Company company;
  final List<String> studentSkills;
  final String serverBaseUrl;

  const CompanyCard({
    super.key,
    required this.company,
    required this.studentSkills,
    required this.serverBaseUrl,
  });

  @override
  State<CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard> {
  bool _isExpanded = false;

  Widget _buildStatusBadge() {
    final req = widget.company.interviewRequest;
    if (req == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    Color bg;
    Color text;
    String label;
    IconData icon;

    if (req.status == 'Pending') {
      if (req.requestedBy == 'Company') {
        bg = isDark
            ? Colors.purple.shade900.withValues(alpha: 0.3)
            : Colors.purple.shade50;
        text = isDark ? Colors.purple.shade300 : Colors.purple;
        label = "Invited";
        icon = Icons.mail_outline;
      } else {
        bg = isDark
            ? Colors.orange.shade900.withValues(alpha: 0.3)
            : Colors.orange.shade50;
        text = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
        label = "Sent";
        icon = Icons.send;
      }
    } else if (req.status == 'Accepted') {
      bg = isDark
          ? Colors.green.shade900.withValues(alpha: 0.3)
          : Colors.green.shade50;
      text = isDark ? Colors.green.shade300 : Colors.green.shade700;
      label = "Accepted";
      icon = Icons.check_circle_outline;
    } else {
      bg = isDark
          ? Colors.indigo.shade900.withValues(alpha: 0.3)
          : Colors.indigo.shade50;
      text = isDark ? Colors.indigo.shade300 : Colors.indigo.shade700;
      label = "Under Review";
      icon = Icons.hourglass_top;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withValues(alpha: 1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillMatchIndicator() {
    final requiredSkills = widget.company.jobs
        .expand((j) => j.requiredSkills)
        .toSet()
        .toList();
    if (requiredSkills.isEmpty) return const SizedBox.shrink();

    int matchedCount = 0;
    for (var req in requiredSkills) {
      if (widget.studentSkills.any(
        (s) => s.toLowerCase() == req.toLowerCase(),
      )) {
        matchedCount++;
      }
    }

    final double percentage = matchedCount / requiredSkills.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    Color color = percentage >= 0.75
        ? (isDark ? Colors.green.shade300 : Colors.green)
        : (percentage >= 0.4
              ? (isDark ? Colors.orange.shade300 : Colors.orange)
              : (isDark ? Colors.grey.shade400 : Colors.grey));
    if (percentage == 0) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: isMobile ? 4 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "${(percentage * 100).toInt()}% Skill Match",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 10 : 11,
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    required Color iconColor,
    required Color backgroundColor,
    Color? textColor,
    bool isMobile = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 8 : (isMobile ? 8 : 10),
          vertical: isMobile ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? iconColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final hasDescription =
        company.description != null && company.description!.trim().isNotEmpty;
    final hasJobs = company.jobs.isNotEmpty;
    final hasExpandableContent = hasDescription || hasJobs;
    final String? logoUrl =
        (company.logoUrl != null && company.logoUrl!.isNotEmpty)
        ? (company.logoUrl!.startsWith('http')
              ? company.logoUrl
              : "${widget.serverBaseUrl}${company.logoUrl}")
        : null;

    // 🔹 Theme Colors
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final subTextColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor, // 🔹 Theme
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 10.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isMobile ? 38 : 50,
                    height: isMobile ? 38 : 50,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade200,
                      ),
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
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 15 : 16,
                            color: textColor,
                          ), // 🔹 Theme
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (company.industry != null)
                              Flexible(
                                child: Text(
                                  company.industry!,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  ), // 🔹 Theme
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(),
                          ],
                        ),
                        _buildSkillMatchIndicator(),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildActionIcon(
                        icon: Icons.work_outline,
                        label: company.jobCount.toString(),
                        onTap: hasExpandableContent
                            ? () => setState(() => _isExpanded = !_isExpanded)
                            : () {},
                        iconColor: isDark ? Colors.blue.shade300 : Colors.blue,
                        backgroundColor: isDark
                            ? Colors.blue.shade900.withValues(alpha: 0.3)
                            : Colors.blue.shade50,
                        textColor: isDark ? Colors.blue.shade300 : Colors.blue,
                        isMobile: isMobile,
                      ),
                      if (company.website != null)
                        _buildActionIcon(
                          icon: Icons.language,
                          onTap: () => launchUrl(
                            Uri.parse(company.website!),
                            mode: LaunchMode.externalApplication,
                          ),
                          iconColor: subTextColor ?? Colors.grey.shade700,
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          isMobile: isMobile,
                        ),
                      if (hasExpandableContent)
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: subTextColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Divider(
                height: 1,
                color: dividerColor.withValues(alpha: 0.1),
              ), // 🔹 Theme
              SizedBox(height: isMobile ? 6 : 8),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (company.isWalkInInterviewing)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 7 : 8,
                        vertical: isMobile ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green.shade900.withValues(alpha: 0.3)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.green.shade700
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Text(
                        "Walk-In Interviewing",
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.green.shade300
                              : Colors.green.shade700,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  const SizedBox.shrink(),
                ],
              ),

              // Expanded Content
              AnimatedSize(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: (_isExpanded && hasExpandableContent)
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          Divider(color: dividerColor.withValues(alpha: 0.1)),
                          const SizedBox(height: 8),
                          if (hasDescription)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                company.description!,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Job List (Using basic list for brevity, logic remains same)
                          if (hasJobs)
                            ...company.jobs.map(
                              (job) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  "• ${job.jobTitle} (${job.numberOfJobs} position${job.numberOfJobs == 1 ? '' : 's'})",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                ),
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
