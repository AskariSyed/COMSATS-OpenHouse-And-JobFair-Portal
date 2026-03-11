import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:student_job_fair_portal/model/notice.dart';

class NoticeProvider with ChangeNotifier {
  List<Notice> _notices = [];
  bool _isLoading = false;
  String? _error;

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static String get baseUrl => BackendConfig.apiBaseUrl;

  Future<void> fetchNotices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        _error = "Authentication required";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/Student/notices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _notices = data.map((json) => Notice.fromJson(json)).toList();
        _error = null;
      } else if (response.statusCode == 401) {
        _error = "Session expired. Please login again.";
      } else {
        _error = "Failed to load notices";
      }
    } catch (e) {
      _error = "Connection error: $e";
      if (kDebugMode) {
        print("Error fetching notices: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
