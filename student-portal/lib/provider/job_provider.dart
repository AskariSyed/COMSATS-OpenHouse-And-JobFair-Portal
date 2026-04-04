import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:student_job_fair_portal/model/job.dart';
import 'package:student_job_fair_portal/mixins/enums.dart';

class JobProvider with ChangeNotifier {
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  List<dynamic> _recommendedJobs = []; // Store recommended jobs
  bool _isLoading = false;
  bool _isLoadingRecommended = false;
  String? _error;
  int _searchRequestId = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  int _pageSize = 6;

  List<Job> get displayJobs => _filteredJobs;
  List<dynamic> get recommendedJobs => _recommendedJobs;
  bool get isLoading => _isLoading;
  bool get isLoadingRecommended => _isLoadingRecommended;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;

  final String baseUrl = BackendConfig.apiBaseUrl;

  Future<void> fetchJobs(String token, {int page = 1, int pageSize = 6}) async {
    _setLoading(true);
    _error = null;
    _currentPage = page;
    _pageSize = pageSize;

    // NOTE: keeping old data while loading

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/jobs?page=$page&pageSize=$pageSize"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final jobResponse = JobListResponse.fromJson(data);
        _jobs = jobResponse.jobs;
        _filteredJobs = List.from(_jobs);
        _currentPage = jobResponse.page;
        _pageSize = jobResponse.pageSize;
        _totalPages = jobResponse.totalPages;
      } else if (response.statusCode == 404) {
        _jobs = [];
        _filteredJobs = [];
        _currentPage = 1;
        _totalPages = 1;
        _error = "No jobs available at the moment.";
      } else {
        _error = "Failed to load jobs. Status: ${response.statusCode}";
      }
    } catch (e) {
      _error = "Error fetching jobs: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchJobs(
    String query, {
    String? token,
    List<JobType>? jobTypes,
    int page = 1,
    int pageSize = 6,
  }) {
    return _searchJobs(
      query,
      token: token,
      jobTypes: jobTypes,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> _searchJobs(
    String query, {
    String? token,
    List<JobType>? jobTypes,
    int page = 1,
    int pageSize = 6,
  }) async {
    final trimmedQuery = query.trim();
    final currentRequestId = ++_searchRequestId;
    final selectedJobTypes = jobTypes ?? const <JobType>[];
    _currentPage = page;
    _pageSize = pageSize;

    if (token == null || token.isEmpty) {
      if (trimmedQuery.isEmpty) {
        _filteredJobs = _applyJobFilters(_jobs, selectedJobTypes);
      } else {
        final lowerQuery = trimmedQuery.toLowerCase();
        _filteredJobs = _jobs.where((job) {
          final queryMatch =
              job.jobTitle.toLowerCase().contains(lowerQuery) ||
              job.companyName.toLowerCase().contains(lowerQuery) ||
              job.requiredSkills.any(
                (s) => s.toLowerCase().contains(lowerQuery),
              );
          final typeMatch =
              selectedJobTypes.isEmpty ||
              selectedJobTypes.contains(job.jobType);
          return queryMatch && typeMatch;
        }).toList();
      }
      notifyListeners();
      return;
    }

    try {
      final queryParameters = <String, String>{
        'keyword': trimmedQuery,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (selectedJobTypes.isNotEmpty) {
        queryParameters['jobTypes'] = selectedJobTypes
            .map((type) => type.name)
            .join(',');
      }

      final response = await http.get(
        Uri.parse(
          "$baseUrl/Student/jobs/search",
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
        final apiJobs = data is Map<String, dynamic>
            ? (data['jobs'] as List<dynamic>?)
                      ?.map((x) => Job.fromJson(x))
                      .toList() ??
                  []
            : <Job>[];
        final localResults = _applyLocalJobSearch(
          _jobs,
          trimmedQuery,
          selectedJobTypes,
        );
        _filteredJobs = _mergeJobs(localResults, apiJobs);
        _currentPage = data is Map<String, dynamic>
            ? (data['page'] ?? page)
            : page;
        _pageSize = data is Map<String, dynamic>
            ? (data['pageSize'] ?? pageSize)
            : pageSize;
        _totalPages = data is Map<String, dynamic>
            ? (data['totalPages'] ?? 1)
            : 1;
        notifyListeners();
      } else if (response.statusCode == 404) {
        _filteredJobs = [];
        _totalPages = 1;
        notifyListeners();
      }
    } catch (_) {
      if (currentRequestId == _searchRequestId) {
        if (trimmedQuery.isEmpty) {
          _filteredJobs = _applyJobFilters(_jobs, selectedJobTypes);
        } else {
          _filteredJobs = _applyLocalJobSearch(
            _jobs,
            trimmedQuery,
            selectedJobTypes,
          );
        }
        notifyListeners();
      }
    }
  }

  List<Job> _applyLocalJobSearch(
    List<Job> jobs,
    String query,
    List<JobType> selectedJobTypes,
  ) {
    final lowerQuery = query.toLowerCase();
    return jobs.where((job) {
      final queryMatch =
          job.jobTitle.toLowerCase().contains(lowerQuery) ||
          job.companyName.toLowerCase().contains(lowerQuery) ||
          job.requiredSkills.any((s) => s.toLowerCase().contains(lowerQuery));
      final typeMatch =
          selectedJobTypes.isEmpty || selectedJobTypes.contains(job.jobType);
      return queryMatch && typeMatch;
    }).toList();
  }

  List<Job> _mergeJobs(List<Job> localJobs, List<Job> apiJobs) {
    final merged = <int, Job>{};

    for (final job in localJobs) {
      merged[job.jobId] = job;
    }

    for (final job in apiJobs) {
      merged[job.jobId] = job;
    }

    return merged.values.toList();
  }

  List<Job> _applyJobFilters(List<Job> jobs, List<JobType> selectedJobTypes) {
    if (selectedJobTypes.isEmpty) {
      return List.from(jobs);
    }

    return jobs.where((job) => selectedJobTypes.contains(job.jobType)).toList();
  }

  // ✅ NEW: Fetch recommended jobs based on student skills
  Future<void> fetchRecommendedJobs(String token) async {
    _isLoadingRecommended = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/jobs/recommended"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _recommendedJobs = data is List ? data : [];
        _error = null;
      } else if (response.statusCode == 400) {
        // User doesn't have skills yet
        _recommendedJobs = [];
        _error = null; // Don't show error for missing skills
      } else {
        _recommendedJobs = [];
        _error = "Failed to load recommendations.";
      }
    } catch (e) {
      _recommendedJobs = [];
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
}
