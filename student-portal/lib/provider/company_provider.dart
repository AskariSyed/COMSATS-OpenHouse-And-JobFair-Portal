import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:student_job_fair_portal/model/company.dart';

class CompanyProvider with ChangeNotifier {
  // State Variables
  List<Company> _companies = [];
  List<Company> _filteredCompanies = [];
  CompanyDetail? _selectedCompany;

  // 🔹 NEW: Cache map to store visited company profiles
  final Map<int, CompanyDetail> _detailsCache = {};

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Company> get companies =>
      _filteredCompanies.isEmpty && _companies.isNotEmpty
      ? _companies
      : _filteredCompanies;

  List<Company> get displayCompanies => _filteredCompanies;
  CompanyDetail? get selectedCompany => _selectedCompany;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Base URL
  final String baseUrl = "http://192.168.137.1:5158/api";

  /// Fetches the list of companies from the API
  Future<void> fetchCompanies(String token) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/companies"),
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
      } else if (response.statusCode == 404) {
        _companies = [];
        _filteredCompanies = [];
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
  void searchCompanies(String query, List<String> studentSkills) {
    if (query.isEmpty) {
      _filteredCompanies = List.from(_companies);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredCompanies = _companies.where((company) {
        final nameMatch = company.name.toLowerCase().contains(lowerQuery);
        final industryMatch =
            company.industry?.toLowerCase().contains(lowerQuery) ?? false;

        // Check jobs
        final jobMatch = company.jobs.any((job) {
          final titleMatch = job.jobTitle.toLowerCase().contains(lowerQuery);
          final skillMatch = job.requiredSkills.any(
            (skill) => skill.toLowerCase().contains(lowerQuery),
          );
          return titleMatch || skillMatch;
        });

        return nameMatch || industryMatch || jobMatch;
      }).toList();
    }

    sortCompaniesBySkillMatch(studentSkills);
    notifyListeners();
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
