import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:student_job_fair_portal/screens/company_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

// Providers & Models
import 'package:student_job_fair_portal/provider/company_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart'; // 🔹 Theme
import 'package:student_job_fair_portal/model/company.dart';

// Screens

// Widgets
import 'package:student_job_fair_portal/widgets/beautiful_appbar.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/beautiful_navigation.dart'; // 🔹 NEW
import 'package:student_job_fair_portal/widgets/web_footer.dart';
import 'package:student_job_fair_portal/widgets/generate_sidebaritem.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final String _serverBaseUrl = "http://192.168.137.1:5158";
  late List<CollapsibleItem> _sidebarItems;
  final String _currentRoute = 'Companies';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIndustries = {};
  bool _showOnlyHiring = false;
  String _selectedSortOption = 'Name (A-Z)'; // Default sort

  final List<String> _implementedRoutes = [
    'Profile',
    'Dashboard',
    'Companies',
    'Jobs',
    'Requests',
    'Interviews',
  ];

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
    final companyProvider = Provider.of<CompanyProvider>(
      context,
      listen: false,
    );

    if (studentProvider.token != null) {
      await companyProvider.fetchCompanies(studentProvider.token!);
    }
  }

  void _onSearchChanged(String query) {
    final studentSkills =
        Provider.of<StudentProvider>(context, listen: false).student?.skills ??
        [];
    Provider.of<CompanyProvider>(
      context,
      listen: false,
    ).searchCompanies(query, studentSkills);
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    // 🔹 Theme Colors
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    final String? profileImageUrl =
        (student?.profilePicUrl != null && student!.profilePicUrl!.isNotEmpty)
        ? (student.profilePicUrl!.startsWith('http')
              ? student.profilePicUrl
              : _serverBaseUrl + student.profilePicUrl!)
        : null;

    final bool showShimmer =
        companyProvider.isLoading && companyProvider.companies.isEmpty;

    // Filter companies
    var filteredCompanies = companyProvider.companies.where((company) {
      if (_showOnlyHiring && company.jobCount == 0) return false;
      if (_selectedIndustries.isNotEmpty) {
        if (company.industry == null ||
            !_selectedIndustries.contains(company.industry)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort companies
    if (_selectedSortOption == 'Name (A-Z)') {
      filteredCompanies.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (_selectedSortOption == 'Name (Z-A)') {
      filteredCompanies.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
    } else if (_selectedSortOption == 'Most Openings') {
      filteredCompanies.sort((a, b) => b.jobCount.compareTo(a.jobCount));
    }

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
            body: Stack(
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
                        showShimmer
                            ? _buildShimmerGrid(isMobile: true)
                            : companyProvider.error != null &&
                                  companyProvider.companies.isEmpty
                            ? SizedBox(
                                height: constraints.maxHeight * 0.7,
                                child: Center(
                                  child: Text(
                                    companyProvider.error!,
                                    style: TextStyle(
                                      color: textColor,
                                    ), // 🔹 Theme
                                  ),
                                ),
                              )
                            : filteredCompanies.isEmpty
                            ? SizedBox(
                                height: constraints.maxHeight * 0.7,
                                child: Center(
                                  child: Text(
                                    "No companies match your filters.",
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                              )
                            : _buildCompaniesGrid(
                                filteredCompanies,
                                student?.skills ?? [],
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
            bottomNavigationBar: const BeautifulMobileNavBar(currentIndex: 3),
          );
        } else {
          // ==================================================================
          // WEB LAYOUT (Themed)
          // ==================================================================
          _sidebarItems = generateSidebarItems(
            context,
            setState,
            _currentRoute,
          );

          return Scaffold(
            backgroundColor: scaffoldBg, // 🔹 Theme
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
                                            "Participating Companies",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      primaryColor, // 🔹 Theme
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Browse companies offering jobs at the fair.",
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color, // 🔹 Theme
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
                                      ? _buildShimmerGrid(isMobile: false)
                                      : filteredCompanies.isEmpty
                                      ? const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Text("No companies found."),
                                          ),
                                        )
                                      : _buildCompaniesGrid(
                                          filteredCompanies,
                                          student?.skills ?? [],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search company name, industry...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade200,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
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
              color: (_selectedIndustries.isNotEmpty || _showOnlyHiring)
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).iconTheme.color,
            ),
            tooltip: "Filter Companies",
          ),
        ),
      ],
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
                      onPressed: () => Navigator.pop(context),
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
                serverBaseUrl: _serverBaseUrl,
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

  // ... (Keep _getJobTypeString, _buildStatusBadge, _buildSkillMatchIndicator logic same) ...
  // [Omitted for brevity, logic handles colors internally]

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

  Widget _buildStatusBadge() {
    final req = widget.company.interviewRequest;
    if (req == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade50;
      text = isDark ? Colors.red.shade300 : Colors.red.shade700;
      label = "Rejected";
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              fontSize: 11,
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
    Color color = percentage >= 0.75
        ? (isDark ? Colors.green.shade300 : Colors.green)
        : (percentage >= 0.4
              ? (isDark ? Colors.orange.shade300 : Colors.orange)
              : (isDark ? Colors.grey.shade400 : Colors.grey));
    if (percentage == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "${(percentage * 100).toInt()}% Skill Match",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
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
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isMobile ? 42 : 50,
                    height: isMobile ? 42 : 50,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: subTextColor,
                        ), // 🔹 Theme
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: dividerColor.withValues(alpha: 0.1),
              ), // 🔹 Theme
              const SizedBox(height: 8),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.shade900.withValues(alpha: 0.3)
                                  : Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.work_outline,
                              size: 14,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${company.jobCount} Jobs",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      if (company.isWalkInInterviewing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade700,
                            ),
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
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.language,
                            size: 18,
                            color: subTextColor,
                          ), // 🔹 Theme
                        ),
                      ),
                    ),
                ],
              ),

              // Expanded Content
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          Divider(color: dividerColor.withValues(alpha: 0.1)),
                          const SizedBox(height: 8),
                          if (company.description != null &&
                              company.description!.trim().isNotEmpty)
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
                          if (company.jobs.isNotEmpty)
                            ...company.jobs.map(
                              (job) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  "• ${job.jobTitle}",
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
