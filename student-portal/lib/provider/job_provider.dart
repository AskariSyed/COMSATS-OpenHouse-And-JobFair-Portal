import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:student_job_fair_portal/model/job.dart';

class JobProvider with ChangeNotifier {
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  bool _isLoading = false;
  String? _error;

  List<Job> get displayJobs => _filteredJobs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String baseUrl = BackendConfig.apiBaseUrl;

  Future<void> fetchJobs(String token) async {
    _setLoading(true);
    _error = null;

    // NOTE: keeping old data while loading

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/jobs"),
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
      } else if (response.statusCode == 404) {
        _jobs = [];
        _filteredJobs = [];
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

  void searchJobs(String query) {
    if (query.isEmpty) {
      _filteredJobs = List.from(_jobs);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredJobs = _jobs.where((job) {
        return job.jobTitle.toLowerCase().contains(lowerQuery) ||
            job.companyName.toLowerCase().contains(lowerQuery) ||
            job.requiredSkills.any((s) => s.toLowerCase().contains(lowerQuery));
      }).toList();
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
