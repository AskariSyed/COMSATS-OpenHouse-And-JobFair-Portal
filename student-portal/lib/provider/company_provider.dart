import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:student_job_fair_portal/model/company.dart';

class CompanyProvider with ChangeNotifier {
  // State Variables
  List<Company> _companies = [];
  List<Company> _filteredCompanies = [];
  CompanyDetail? _selectedCompany;
  List<dynamic> _recommendedCompanies = []; // Store recommended companies

  // 🔹 NEW: Cache map to store visited company profiles
  final Map<int, CompanyDetail> _detailsCache = {};

  bool _isLoading = false;
  bool _isLoadingRecommended = false;
  String? _error;
  int _searchRequestId = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  int _pageSize = 8;

  // Getters
  List<Company> get companies => _filteredCompanies;

  List<Company> get displayCompanies => _filteredCompanies;
  List<dynamic> get recommendedCompanies => _recommendedCompanies;
  CompanyDetail? get selectedCompany => _selectedCompany;

  bool get isLoading => _isLoading;
  bool get isLoadingRecommended => _isLoadingRecommended;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;

  // Base URL
  final String baseUrl = BackendConfig.apiBaseUrl;

  /// Fetches the list of companies from the API
  Future<void> fetchCompanies(
    String token, {
    int page = 1,
    int pageSize = 8,
  }) async {
    _setLoading(true);
    _error = null;
    _currentPage = page;
    _pageSize = pageSize;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/companies?page=$page&pageSize=$pageSize"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final companyResponse = CompanyListResponse.fromJson(data);
        _companies = companyResponse.companies;
        _filteredCompanies = List.from(_companies);
        _currentPage = companyResponse.page;
        _pageSize = companyResponse.pageSize;
        _totalPages = companyResponse.totalPages;
      } else if (response.statusCode == 404) {
        _companies = [];
        _filteredCompanies = [];
        _currentPage = 1;
        _totalPages = 1;
        _error = "No companies available for your job fair yet.";
      } else {
        _error = "Failed to load companies. Status: ${response.statusCode}";
        debugPrint("❌ Error fetching companies: ${response.body}");
      }
    } catch (e) {
      _error = "An error occurred: $e";
      debugPrint("❌ Exception fetching companies: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> fetchCompanyDetails(
    int companyId,
    String token, {
    bool forceRefresh = false,
  }) async {
    // 1. Check Cache First
    if (!forceRefresh && _detailsCache.containsKey(companyId)) {
      _selectedCompany = _detailsCache[companyId];
      _error = null;
      notifyListeners();
      return true;
    }

    _setLoading(true);
    _error = null;
    _selectedCompany = null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/companies/$companyId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['company'] != null) {
          // Parse data
          final detail = CompanyDetail.fromJson(data['company']);

          // 🔹 Save to Cache
          _detailsCache[companyId] = detail;

          // Set selected
          _selectedCompany = detail;
          notifyListeners();
          return true;
        }
      } else if (response.statusCode == 404) {
        _error = "Company not found.";
        if (response.body.isNotEmpty) {
          // If body is plain text, use it. If JSON, try to parse 'message'
          try {
            final data = json.decode(response.body);
            if (data is Map && data.containsKey('message')) {
              _error = data['message'];
            }
          } catch (_) {
            _error = response.body;
          }
        }
        debugPrint("❌ Company not found: $_error");
        return false;
      }

      _error = "Failed to load company details. Status: ${response.statusCode}";
      debugPrint("❌ Error fetching company details: ${response.body}");
      return false;
    } catch (e) {
      _error = "Error: $e";
      debugPrint("❌ Exception fetching company details: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- Sorting Logic ---
  void sortCompaniesBySkillMatch(List<String> studentSkills) {
    if (studentSkills.isEmpty) return;

    _filteredCompanies.sort((a, b) {
      int matchA = _calculateMaxSkillMatch(a, studentSkills);
      int matchB = _calculateMaxSkillMatch(b, studentSkills);
      return matchB.compareTo(matchA);
    });
    notifyListeners();
  }

  int _calculateMaxSkillMatch(Company company, List<String> studentSkills) {
    int maxMatch = 0;
    for (var job in company.jobs) {
      int currentMatch = 0;
      for (var skill in job.requiredSkills) {
        if (studentSkills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
          currentMatch++;
        }
      }
      if (currentMatch > maxMatch) {
        maxMatch = currentMatch;
      }
    }
    return maxMatch;
  }

  // --- Search Logic ---
  Future<void> searchCompanies(
    String query,
    List<String> studentSkills, {
    String? token,
    List<String>? industries,
    bool onlyHiring = false,
    int page = 1,
    int pageSize = 8,
  }) {
    return _searchCompanies(
      query,
      studentSkills,
      token: token,
      industries: industries,
      onlyHiring: onlyHiring,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> _searchCompanies(
    String query,
    List<String> studentSkills, {
    String? token,
    List<String>? industries,
    bool onlyHiring = false,
    int page = 1,
    int pageSize = 8,
  }) async {
    final trimmedQuery = query.trim();
    final currentRequestId = ++_searchRequestId;
    final selectedIndustries = (industries ?? const <String>[])
        .where((industry) => industry.trim().isNotEmpty)
        .toSet();
    _currentPage = page;
    _pageSize = pageSize;

    if (token == null || token.isEmpty) {
      if (trimmedQuery.isEmpty) {
        _filteredCompanies = _applyCompanyFilters(
          _companies,
          selectedIndustries,
          onlyHiring: onlyHiring,
        );
      } else {
        _filteredCompanies = _applyLocalCompanySearch(
          _companies,
          trimmedQuery,
          selectedIndustries,
          onlyHiring: onlyHiring,
        );
      }
      sortCompaniesBySkillMatch(studentSkills);
      notifyListeners();
      return;
    }

    try {
      final queryParameters = <String, String>{
        'keyword': trimmedQuery,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (selectedIndustries.isNotEmpty) {
        queryParameters['industries'] = selectedIndustries.join(',');
      }

      if (onlyHiring) {
        queryParameters['onlyHiring'] = 'true';
      }

      final response = await http.get(
        Uri.parse(
          "$baseUrl/Student/companies/search",
        ).replace(queryParameters: queryParameters),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (currentRequestId != _searchRequestId) {
        return;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiCompanies = data is Map<String, dynamic>
            ? (data['companies'] as List<dynamic>?)
                      ?.map((x) => Company.fromJson(x))
                      .toList() ??
                  []
            : <Company>[];

        final localResults = trimmedQuery.isEmpty
            ? _applyCompanyFilters(
                _companies,
                selectedIndustries,
                onlyHiring: onlyHiring,
              )
            : _applyLocalCompanySearch(
                _companies,
                trimmedQuery,
                selectedIndustries,
                onlyHiring: onlyHiring,
              );
        final mergedCompanies = _mergeCompanies(localResults, apiCompanies);
        _filteredCompanies = mergedCompanies;
        _currentPage = data is Map<String, dynamic>
            ? (data['page'] ?? page)
            : page;
        _pageSize = data is Map<String, dynamic>
            ? (data['pageSize'] ?? pageSize)
            : pageSize;
        _totalPages = data is Map<String, dynamic>
            ? (data['totalPages'] ?? 1)
            : 1;
        sortCompaniesBySkillMatch(studentSkills);
        notifyListeners();
      } else if (response.statusCode == 404) {
        _filteredCompanies = [];
        _totalPages = 1;
        notifyListeners();
      }
    } catch (_) {
      if (currentRequestId == _searchRequestId) {
        _filteredCompanies = trimmedQuery.isEmpty
            ? _applyCompanyFilters(
                _companies,
                selectedIndustries,
                onlyHiring: onlyHiring,
              )
            : _applyLocalCompanySearch(
                _companies,
                trimmedQuery,
                selectedIndustries,
                onlyHiring: onlyHiring,
              );
        sortCompaniesBySkillMatch(studentSkills);
        notifyListeners();
      }
    }
  }

  List<Company> _applyLocalCompanySearch(
    List<Company> companies,
    String query,
    Set<String> selectedIndustries, {
    required bool onlyHiring,
  }) {
    final lowerQuery = query.toLowerCase();

    return companies.where((company) {
      final nameMatch = company.name.toLowerCase().contains(lowerQuery);
      final industryMatch =
          company.industry?.toLowerCase().contains(lowerQuery) ?? false;

      final jobMatch = company.jobs.any((job) {
        final titleMatch = job.jobTitle.toLowerCase().contains(lowerQuery);
        final skillMatch = job.requiredSkills.any(
          (skill) => skill.toLowerCase().contains(lowerQuery),
        );
        return titleMatch || skillMatch;
      });

      final matchesQuery = nameMatch || industryMatch || jobMatch;
      final matchesFilters = !onlyHiring || company.jobCount > 0;
      final industryAllowed =
          selectedIndustries.isEmpty ||
          (company.industry != null &&
              selectedIndustries.contains(company.industry));

      return matchesQuery && matchesFilters && industryAllowed;
    }).toList();
  }

  List<Company> _mergeCompanies(
    List<Company> localCompanies,
    List<Company> apiCompanies,
  ) {
    final merged = <int, Company>{};

    for (final company in localCompanies) {
      merged[company.companyId] = company;
    }

    for (final company in apiCompanies) {
      merged[company.companyId] = company;
    }

    return merged.values.toList();
  }

  List<Company> _applyCompanyFilters(
    List<Company> companies,
    Set<String> selectedIndustries, {
    required bool onlyHiring,
  }) {
    return companies.where((company) {
      if (onlyHiring && company.jobCount == 0) return false;
      if (selectedIndustries.isNotEmpty) {
        if (company.industry == null ||
            !selectedIndustries.contains(company.industry)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ✅ NEW: Fetch recommended companies based on student skills
  Future<void> fetchRecommendedCompanies(String token) async {
    _isLoadingRecommended = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/companies/recommended"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _recommendedCompanies = data is List ? data : [];
        _error = null;
      } else if (response.statusCode == 400) {
        // User doesn't have skills yet
        _recommendedCompanies = [];
        _error = null; // Don't show error for missing skills
      } else {
        _recommendedCompanies = [];
        _error = "Failed to load recommendations.";
      }
    } catch (e) {
      _recommendedCompanies = [];
      _error = null; // Don't show error in recommendations
    } finally {
      _isLoadingRecommended = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clear cache when logging out
  void clearCache() {
    _detailsCache.clear();
    _companies = [];
    _filteredCompanies = [];
    _selectedCompany = null;
    notifyListeners();
  }
}
