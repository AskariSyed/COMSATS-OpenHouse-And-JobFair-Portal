import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Import XFile
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_job_fair_portal/model/InterviewRequest.dart';
import 'package:student_job_fair_portal/model/achievement.dart';
import 'package:student_job_fair_portal/model/certification.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/model/education.dart';
import 'package:student_job_fair_portal/model/experience.dart';
import 'package:student_job_fair_portal/model/projectInvitiation.dart';
import 'package:student_job_fair_portal/model/projectMember.dart';
import 'package:student_job_fair_portal/model/student.dart';
import 'package:student_job_fair_portal/model/dashboard_data.dart';
import 'package:student_job_fair_portal/model/interview.dart';
import 'package:student_job_fair_portal/mixins/enums.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';

class StudentProvider with ChangeNotifier {
  Student? _student;
  String? _token;
  bool _isLoading = false;

  Student? get student => _student;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _student != null && _token != null;

  DashboardData? _dashboardData;
  DashboardData? get dashboardData => _dashboardData;
  String? _dashboardError;
  String? get dashboardError => _dashboardError;

  List<ProjectInvitation> _invitations = [];
  List<ProjectInvitation> get invitations => _invitations;
  List<InterviewRequest> _interviewRequests = [];
  List<InterviewRequest> get interviewRequests => _interviewRequests;
  List<Interview> _scheduledInterviews = [];
  List<Interview> get scheduledInterviews => _scheduledInterviews;
  int get pendingCompanyRequestCount => _interviewRequests
      .where(
        (r) =>
            r.requestedBy == RequestedBy.Company &&
            r.status == RequestStatus.Pending,
      )
      .length;

  int get upcomingInterviewCount {
    final now = DateTime.now();
    return _scheduledInterviews.where((i) {
      final status = i.status.toLowerCase();
      return i.scheduledTime != null &&
          i.scheduledTime!.isAfter(now) &&
          (status == 'queued' ||
              status == 'accepted' ||
              status == 'inprogress');
    }).length;
  }

  String? _scheduledInterviewsError;
  String? get scheduledInterviewsError => _scheduledInterviewsError;

  // Base URL for your API
  final String baseUrl = BackendConfig.apiBaseUrl;
  final String imageBaseUrl = BackendConfig.serverBaseUrl;
  // Helper to get auth headers
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  String _extractApiError(
    http.Response response, {
    String fallback = 'Request failed',
  }) {
    String message = response.body.trim();
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded is String) {
        message = decoded;
      }
    } catch (_) {
      // Keep raw response body when it is not JSON.
    }

    if (message.isEmpty) {
      return '$fallback with status ${response.statusCode}';
    }
    return message;
  }

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // --- 1. AUTH & SESSION ---

  void setStudent(Student student) {
    _student = student;
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    notifyListeners();
  }

  Future<void> logout() async {
    _student = null;
    _token = null;
    _dashboardData = null;
    _dashboardError = null;
    _interviewRequests = [];
    _scheduledInterviews = [];
    _invitations = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('authToken')) {
      return false;
    }
    _token = prefs.getString('authToken');

    if (_student == null) {
      _token = null;
      return false;
    }

    notifyListeners();
    return true;
  }

  // --- 2. CORE PROFILE UPDATES ---

  /// ✅ UPDATED FOR WEB & MOBILE
  /// Accepts an XFile directly from image_picker
  Future<bool> uploadProfilePic(XFile xFile) async {
    final lower = xFile.name.toLowerCase();
    final isImage =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
    if (!isImage) {
      debugPrint("❌ Invalid profile image type: ${xFile.name}");
      return false;
    }

    if (_student == null) return false;
    _setLoading(true);

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/Student/profile-pic"),
    )..headers.addAll({"Authorization": "Bearer $_token"});

    // Platform-agnostic way to read bytes and create a multipart file
    final bytes = await xFile.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: xFile.name,
    );

    request.files.add(multipartFile);

    debugPrint("📤 Uploading Profile Pic => ${xFile.name}");

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(resBody);
      _student = _student!.copyWith(
        profilePicUrl: data["profilePicUrl"],
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
    debugPrint("❌ Profile Pic upload failed: $resBody");
    return false;
  }

  Future<bool> uploadGeneratedCv(Uint8List pdfBytes, {String? fileName}) async {
    if (_student == null || pdfBytes.isEmpty) return false;
    _setLoading(true);

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/Student/cv"),
    )..headers.addAll({"Authorization": "Bearer $_token"});

    final cvFileName =
        fileName ??
        "${_student!.registrationNo}_${DateTime.now().millisecondsSinceEpoch}.pdf";

    request.files.add(
      http.MultipartFile.fromBytes('file', pdfBytes, filename: cvFileName),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(resBody);
      _student = _student!.copyWith(
        cvUrl: data["cvUrl"],
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }

    debugPrint("❌ CV upload failed: $resBody");
    return false;
  }

  Future<bool> updatePhoneNumber(String phone) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.put(
      Uri.parse("$baseUrl/Student/phone"),
      headers: _authHeaders,
      // C# PhoneDto expects 'phone' (camelCase)
      body: json.encode({"phone": phone}),
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      _student = _student!.copyWith(
        user: _student!.user.copyWith(phone: phone),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to update phone: ${response.body}");
    return false;
  }

  // --- 3. SKILLS ---

  Future<bool> addSkills(List<String> skills) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.post(
      Uri.parse("$baseUrl/Student/skills/add"),
      headers: _authHeaders,
      // C# SkillsDto expects 'skills' (camelCase)
      body: json.encode({"skills": skills}),
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _student = _student!.copyWith(
        skills: List<String>.from(data['skills'] ?? []),
      );
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to add skills: ${response.body}");
    return false;
  }

  Future<bool> removeSkill(String skill) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.post(
      Uri.parse("$baseUrl/Student/skills/remove"),
      headers: _authHeaders,
      body: json.encode(skill), // Send raw string
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _student = _student!.copyWith(
        skills: List<String>.from(data['skills'] ?? []),
      );
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to remove skill: ${response.body}");
    return false;
  }

  Future<bool> putSkills(List<String> skills) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.put(
      Uri.parse("$baseUrl/Student/skills"),
      headers: _authHeaders,
      // C# SkillsDto expects 'skills' (camelCase)
      body: json.encode({"skills": skills}),
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _student = _student!.copyWith(
        skills: List<String>.from(data['skills'] ?? []),
      );
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to update skills: ${response.body}");
    return false;
  }

  // DTOs like ExperienceAddDto will expect camelCase
  // --- 5. EDUCATION (Full CRUD) ---
  Future<bool> addEducation(Map<String, dynamic> educationData) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Student/Education"),
        headers: _authHeaders,
        body: json.encode(educationData),
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 1. Parse the object (studentId will be 0 here)
        Education newEducation = Education.fromJson(data['education']);

        // 2. 🔹 FIX: Inject the real Student ID from the provider
        newEducation = newEducation.copyWith(studentId: _student!.studentId);

        // 3. Add to list
        final updatedList = List<Education>.from(_student!.educations)
          ..add(newEducation);

        _student = _student!.copyWith(educations: updatedList);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // --- FETCH FULL PROFILE ---
  Future<void> fetchProfile() async {
    if (_token == null) return;

    // Don't trigger global loading here to avoid screen flickering,
    // or handle it gracefully in UI

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/profile"), // Matches the C# endpoint above
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Assuming response is { "student": { ... } }
        if (data['student'] != null) {
          _student = Student.fromJson(data['student']);
          notifyListeners(); // Update UI with new data
        }
      } else {
        debugPrint("Failed to load profile: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> fetchDashboardData() async {
    if (_token == null) return;
    _setLoading(true);
    _dashboardError = null;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/dashboard"),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _dashboardData = DashboardData.fromJson(data);
        notifyListeners();
      } else {
        _dashboardError = "Failed to load dashboard: ${response.statusCode}";
        debugPrint("Failed to load dashboard: ${response.body}");
      }
    } catch (e) {
      _dashboardError = "Error fetching dashboard: $e";
      debugPrint("Error fetching dashboard: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Inside lib/provider/student_provider.dart

  // 🎯 New: Update Name Method
  Future<bool> updateFullName(String fullName) async {
    if (_student == null) return false;
    _setLoading(true);

    // Use PUT or POST based on whether the name already exists.
    // Since C# has both and they perform the same function, we'll use PUT for updates.
    final response = await http.put(
      Uri.parse("$baseUrl/Student/name"),
      headers: _authHeaders,
      body: json.encode({"fullName": fullName}),
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      // Optimistically update the local user object
      _student = _student!.copyWith(
        user: _student!.user.copyWith(fullName: fullName),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to update name: ${response.body}");
    return false;
  }

  Future<bool> updateEducation(
    int educationId,
    Map<String, dynamic> educationData,
  ) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.put(
      Uri.parse(
        "$baseUrl/Student/education/$educationId",
      ), // Uses root /Student/{id} route
      headers: _authHeaders,
      body: json.encode(educationData), // Assuming data is already camelCase
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final updatedEducation = Education.fromJson(data['education']);
      final updatedList = _student!.educations
          .map((e) => e.educationId == educationId ? updatedEducation : e)
          .toList();
      _student = _student!.copyWith(educations: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to update education: ${response.body}");
    return false;
  }

  Future<bool> deleteEducation(int educationId) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.delete(
      Uri.parse(
        "$baseUrl/Student/education/$educationId",
      ), // Uses root /Student/{id} route
      headers: _authHeaders,
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final updatedList = _student!.educations
          .where((e) => e.educationId != educationId)
          .toList();
      _student = _student!.copyWith(educations: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to delete education: ${response.body}");
    return false;
  }

  // --- 6. CERTIFICATION (Full CRUD) ---

  Future<bool> addCertification(Map<String, dynamic> certificationData) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.post(
      Uri.parse("$baseUrl/Student/certifications"),
      headers: _authHeaders,
      body: json.encode(
        certificationData,
      ), // Assuming data is already camelCase
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newCertification = Certification.fromJson(data['certification']);
      final updatedList = List<Certification>.from(_student!.certifications)
        ..add(newCertification);
      _student = _student!.copyWith(certifications: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to add certification: ${response.body}");
    return false;
  }

  Future<bool> updateCertification(
    int certificationId,
    Map<String, dynamic> certificationData,
  ) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.put(
      Uri.parse("$baseUrl/Student/certifications/$certificationId"),
      headers: _authHeaders,
      body: json.encode(
        certificationData,
      ), // Assuming data is already camelCase
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final updatedCertification = Certification.fromJson(
        data['certification'],
      );
      final updatedList = _student!.certifications
          .map(
            (c) =>
                c.certificationId == certificationId ? updatedCertification : c,
          )
          .toList();
      _student = _student!.copyWith(certifications: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to update certification: ${response.body}");
    return false;
  }

  Future<bool> deleteCertification(int certificationId) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.delete(
      Uri.parse("$baseUrl/Student/certifications/$certificationId"),
      headers: _authHeaders,
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final updatedList = _student!.certifications
          .where((c) => c.certificationId != certificationId)
          .toList();
      _student = _student!.copyWith(certifications: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to delete certification: ${response.body}");
    return false;
  }

  Future<bool> addContactLink(Map<String, dynamic> linkData) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.post(
      Uri.parse("$baseUrl/Student/ContactLink"),
      headers: _authHeaders,
      body: json.encode(linkData), // Assumes 'platform' and 'url' (camelCase)
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newLink = ContactLink.fromJson(data['contactLink']);
      final updatedList = List<ContactLink>.from(_student!.contactLinks)
        ..add(newLink);
      _student = _student!.copyWith(contactLinks: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to add contact link: ${response.body}");
    return false;
  }

  Future<bool> updateContactLink(
    int linkId,
    Map<String, dynamic> linkData,
  ) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.put(
      Uri.parse("$baseUrl/Student/$linkId"),
      headers: _authHeaders,
      body: json.encode(linkData),
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final updatedLink = ContactLink.fromJson(data['contactLink']);
      final updatedList = _student!.contactLinks
          .map((c) => c.linkId == linkId ? updatedLink : c)
          .toList();
      _student = _student!.copyWith(contactLinks: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to update contact link: ${response.body}");
    return false;
  }

  Future<bool> deleteContactLink(int linkId) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.delete(
      Uri.parse("$baseUrl/Student/$linkId"),
      headers: _authHeaders,
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final updatedList = _student!.contactLinks
          .where((c) => c.linkId != linkId)
          .toList();
      _student = _student!.copyWith(contactLinks: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to delete contact link: ${response.body}");
    return false;
  }

  Future<bool> createProject(Map<String, dynamic> projectData) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.post(
      Uri.parse("$baseUrl/Student/projects"),
      headers: _authHeaders,
      body: json.encode(
        projectData,
      ), // Assumes 'title', 'type', etc. (camelCase)
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['project'];

      if (projectData['type'] == 2) {
        // 2 = FinalYear
        _student = _student!.copyWith(
          fypTitle: data['title'],
          fypDescription: data['description'],
          fypDemoUrl: data['demoUrl'],
          fypGithubUrl: data['gitHubUrl'],
        );
        notifyListeners();
      }
      return true;
    }
    debugPrint("❌ Failed to create project: ${response.body}");
    return false;
  }
  // --- 7. PROJECT MANAGEMENT ---

  // Inside StudentProvider class

  Future<bool> inviteStudent(int projectId, String regNo) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Student/projects/$projectId/invite"),
        headers: _authHeaders,
        body: json.encode({"registrationNumber": regNo}),
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        return true;
      }

      // --- Handle Error Response (Non-200 status code) ---
      String errorBody = response.body;
      String errorMessage =
          "Invitation failed. Server returned status ${response.statusCode}.";

      try {
        final errorJson = json.decode(errorBody);
        // Try to extract the message from the backend response structure
        errorMessage =
            errorJson['Message'] ?? errorJson['message'] ?? errorBody;
      } catch (_) {
        // If response body is not JSON (e.g., raw string error), use the raw body.
        errorMessage = errorBody.isNotEmpty ? errorBody : errorMessage;
      }

      // 🔹 Check for the specific error and append the instruction
      if (errorMessage.contains("Student not found") ||
          errorMessage.contains("registration number")) {
        errorMessage += " Ask your friend to sign up on OpenHouse Portal.";
      }

      debugPrint("❌ Invite failed: $errorMessage");

      // 🔹 Throw the processed error. This will be caught by the dialog's onSave block.
      throw Exception(errorMessage);
    } catch (e) {
      _setLoading(false);
      rethrow; // Re-throw the exception so the UI's catch block can display it
    }
  }

  // Leave a project (Remove Self)
  Future<bool> leaveProject(int projectId) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      // Endpoint: DELETE api/projects/{projectId}/members/{studentId}
      final response = await http.delete(
        Uri.parse(
          "$baseUrl/Student/projects/$projectId/members/${_student!.studentId}",
        ),
        headers: _authHeaders,
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        // Remove locally to update UI instantly
        _student!.projects.removeWhere((p) => p.projectId == projectId);
        notifyListeners();
        return true;
      }
      debugPrint("❌ Leave project failed: ${response.body}");
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Remove a member from a project (Team Lead only)
  Future<bool> removeMember(int projectId, int memberStudentId) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      // Endpoint: DELETE api/projects/{projectId}/members/{memberStudentId}
      final response = await http.delete(
        Uri.parse(
          "$baseUrl/Student/projects/$projectId/members/$memberStudentId",
        ),
        headers: _authHeaders,
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        return true;
      }
      debugPrint("❌ Remove member failed: ${response.body}");
      return false;
    } catch (e) {
      _setLoading(false);
      debugPrint("❌ Remove member error: $e");
      return false;
    }
  }

  // Edit Project Details
  // Note: Ensure you have [HttpPut("projects/{id}")] on backend similar to CreateProject
  Future<bool> updateProject(int projectId, Map<String, dynamic> data) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      final response = await http.put(
        Uri.parse(
          "$baseUrl/Student/projects/$projectId",
        ), // Standard REST convention
        headers: _authHeaders,
        body: json.encode(data),
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        // Trigger a fetch to refresh the list with new details
        await fetchProfile();
        return true;
      }
      debugPrint("❌ Update project failed: ${response.body}");
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchInvitations() async {
    if (_student == null) return;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/projects/invitations"),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _invitations = data
            .map((json) => ProjectInvitation.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching invitations: $e");
    }
  }

  // 2. Respond to Invitation (Accept/Reject)
  Future<bool> respondToInvitation(int inviteId, bool accept) async {
    try {
      _setLoading(true);
      final response = await http.post(
        Uri.parse(
          "$baseUrl/Student/projects/invitations/$inviteId/respond?accept=$accept",
        ),
        headers: _authHeaders,
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        // Remove from local list immediately
        _invitations.removeWhere((i) => i.id == inviteId);
        // If accepted, we should refresh the full profile to see the new project in the list
        if (accept) await fetchProfile();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // 3. Get Members of a specific Project
  Future<List<ProjectMember>> fetchProjectMembers(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/projects/$projectId/members"),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProjectMember.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching members: $e");
      return [];
    }
  }

  Future<bool> addAchievement(Map<String, dynamic> achievementData) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.post(
      Uri.parse("$baseUrl/Student/achievements"),
      headers: _authHeaders,
      body: json.encode(achievementData),
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final achievementJson =
          (data['achievement'] ?? data['Achievement']) as Map<String, dynamic>?;

      if (achievementJson != null) {
        // 1. Create the new Achievement model instance
        final newAchievement = Achievement.fromJson(achievementJson);

        // 2. Inject StudentId
        final studentId = _student!.studentId;
        final finalAchievement = newAchievement.copyWith(studentId: studentId);

        // 3. 💥 FIX: Resolve Type Collision by mapping existing items
        _student = _student!.copyWith(
          achievements: [
            // Force existing items to be re-read into the current type definition
            ..._student!.achievements.map((a) => a),
            finalAchievement,
          ],
        );

        notifyListeners();
        return true;
      }
      return false;
    }
    return false;
  }

  Future<bool> updateAchievement(
    int achievementId,
    Map<String, dynamic> achievementData,
  ) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.put(
      Uri.parse("$baseUrl/Student/achievements/$achievementId"),
      headers: _authHeaders,
      body: json.encode(achievementData),
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      // Ideally, refresh the full list or implement local update logic
      await fetchProfile();
      return true;
    }
    debugPrint("❌ Failed to update achievement: ${response.body}");
    return false;
  }

  Future<bool> deleteAchievement(int achievementId) async {
    if (_student == null) return false;
    _setLoading(true);

    final response = await http.delete(
      Uri.parse("$baseUrl/Student/achievements/$achievementId"),
      headers: _authHeaders,
    );
    _setLoading(false);

    if (response.statusCode == 200) {
      // Remove locally to update UI immediately
      final updatedList = _student!.achievements
          .where((a) => a.achievementId != achievementId)
          .toList();

      _student = _student!.copyWith(achievements: updatedList);
      notifyListeners();
      return true;
    }
    debugPrint("❌ Failed to delete achievement: ${response.body}");
    return false;
  }

  Future<String?> sendInterviewRequest(int companyId) async {
    if (_student == null) return "Not logged in";

    // Note: We do not use _setLoading(true) here to prevent blocking the whole UI.
    // The local widget calling this function should handle its own loading state.

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Student/interview-requests/send"),
        headers: _authHeaders,
        body: json.encode({"companyId": companyId}),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return _extractApiError(response, fallback: 'Request failed');
      }
    } catch (e) {
      return "Network error: $e";
    }
  }

  Future<void> fetchInterviewRequests() async {
    if (_student == null) return;
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/interview-requests"),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['requests'] != null) {
          _interviewRequests = (data['requests'] as List)
              .map((json) => InterviewRequest.fromJson(json))
              .toList();
        } else {
          _interviewRequests = [];
        }
      } else if (response.statusCode == 404) {
        _interviewRequests = [];
      }
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchScheduledInterviews() async {
    if (_student == null) return;
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/interviews/scheduled"),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          _scheduledInterviews = (data)
              .map((json) => Interview.fromJson(json))
              .toList();
          _scheduledInterviewsError = null;
        } else {
          _scheduledInterviews = [];
        }
      } else if (response.statusCode == 404) {
        _scheduledInterviews = [];
        _scheduledInterviewsError = null;
      } else {
        _scheduledInterviews = [];
        _scheduledInterviewsError = "Failed to load interviews";
      }
    } catch (e) {
      debugPrint("Error fetching scheduled interviews: $e");
      _scheduledInterviews = [];
      _scheduledInterviewsError = "Error: $e";
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<String?> withdrawRequest(int requestId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/Student/interview-requests/$requestId"),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        _interviewRequests.removeWhere((r) => r.requestId == requestId);
        notifyListeners();
        return null; // Success
      }
      return "Failed to withdraw: ${response.body}";
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String?> acceptCompanyInvite(int requestId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Student/interview-requests/$requestId/accept"),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        await fetchInterviewRequests(); // Refresh list
        return null;
      }
      return _extractApiError(response, fallback: 'Failed to accept');
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String?> rejectCompanyInvite(int requestId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Student/interview-requests/$requestId/reject"),
        headers: _authHeaders,
        body: json.encode({"reason": reason}),
      );

      if (response.statusCode == 200) {
        await fetchInterviewRequests(); // Refresh list
        return null;
      }
      return _extractApiError(response, fallback: 'Failed to reject');
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<bool> updateCGPA(double newCgpa) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/Student/cgpa"),
        headers: _authHeaders,
        body: json.encode({"cgpa": newCgpa}),
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        // Update local state
        _student = _student!.copyWith(cgpa: newCgpa, updatedAt: DateTime.now());
        notifyListeners();
        return true;
      }
      debugPrint("❌ Failed to update CGPA: ${response.body}");
      return false;
    } catch (e) {
      _setLoading(false);
      debugPrint("Error updating CGPA: $e");
      return false;
    }
  }
  // Open lib/provider/student_provider.dart and add these methods inside the StudentProvider class

  // --------------------------------------------------------------------------
  // CGPA MANAGEMENT
  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  // EXPERIENCE MANAGEMENT
  // --------------------------------------------------------------------------

  // Although GetProfile loads experiences, this is useful for refreshing just this list
  Future<void> fetchExperiences() async {
    if (_student == null) return;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Student/experiences"),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Experience> experiences = data
            .map((json) => Experience.fromJson(json))
            .toList();

        _student = _student!.copyWith(experiences: experiences);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching experiences: $e");
    }
  }

  Future<int> sendPasswordResetOtp(String emailOrRegNo) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Auth/forgot-password/send-otp"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"emailOrRegNo": emailOrRegNo}),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Success - return userId
        if (data['userId'] != null) {
          return data['userId'];
        } else {
          throw Exception(
            data['message'] ??
                data['Message'] ??
                "If the account exists, an OTP has been sent.",
          );
        }
      } else if (response.statusCode == 400) {
        // Parse error response for specific error codes
        try {
          final data = json.decode(response.body);
          final code = data['code'] ?? data['Code'] ?? '';
          final message = data['message'] ?? data['Message'] ?? '';

          // Handle specific error codes
          if (code == 'STUDENT_NOT_FOUND') {
            throw Exception(
              message.isNotEmpty
                  ? message
                  : "Student account not found. Please verify your registration number.",
            );
          } else if (code == 'ACCOUNT_NOT_FOUND') {
            throw Exception(
              message.isNotEmpty
                  ? message
                  : "Account not found. Please verify your email address.",
            );
          } else if (code == 'INVALID_ACCOUNT_TYPE') {
            throw Exception(
              message.isNotEmpty
                  ? message
                  : "Not a student account. Please use your registration number.",
            );
          } else {
            // Generic error message
            throw Exception(
              message.isNotEmpty
                  ? message
                  : "Failed to send OTP. Please try again.",
            );
          }
        } catch (e) {
          if (e.toString().contains('Exception:')) {
            rethrow;
          }
          // If JSON parsing fails, throw generic error
          throw Exception("Invalid request. Please check your input.");
        }
      } else if (response.statusCode == 404) {
        throw Exception("Account not found. Please verify your details.");
      } else if (response.statusCode == 500) {
        throw Exception("Server error. Please try again later.");
      } else {
        throw Exception("Failed to send OTP. Please try again.");
      }
    } catch (e) {
      _setLoading(false);
      // Clean up the exception message for the UI
      final msg = e.toString().replaceAll("Exception: ", "");
      throw Exception(msg);
    }
  }

  Future<String?> resetPassword({
    required int userId,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Auth/forgot-password/verify-otp"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "userId": userId,
          "otp": otp,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        String message = '';
        try {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            message = (data['message'] ?? data['Message'] ?? '').toString();
          }
        } catch (_) {
          message = response.body;
        }

        if (message.trim().isEmpty) {
          message = response.body;
        }

        final normalizedMessage = message.toLowerCase();

        if (response.statusCode == 400) {
          if (normalizedMessage.contains("expired")) {
            return "OTP expired. Please request a new OTP.";
          } else if (normalizedMessage.contains("not found")) {
            return "OTP not found. Please request a new OTP.";
          } else if (normalizedMessage.contains("already been used")) {
            return "This OTP has already been used. Please request a new one.";
          } else if (normalizedMessage.contains("invalid otp")) {
            return "Invalid OTP. Please check and try again.";
          } else {
            return message.trim().isNotEmpty
                ? message.trim()
                : "Invalid request. Please try again.";
          }
        } else if (response.statusCode == 404) {
          return "User not found. Please restart the password reset process.";
        } else if (response.statusCode == 500) {
          return "Server error. Please try again later.";
        } else {
          return message.trim().isNotEmpty
              ? message.trim()
              : "Failed to reset password.";
        }
      }
    } catch (e) {
      _setLoading(false);
      return "Network error. Please check your connection and try again.";
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/change-password"),
        headers: _authHeaders,
        body: json.encode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        return; // Success
      } else {
        // Parse error response
        try {
          final data = json.decode(response.body);
          String errorMessage =
              data['message'] ??
              data['Message'] ??
              data['error'] ??
              data['Error'] ??
              'Failed to change password';
          throw Exception(errorMessage);
        } catch (e) {
          // If JSON parsing fails, use the raw response body
          if (response.body.isNotEmpty) {
            throw Exception(response.body);
          }
          throw Exception('Failed to change password');
        }
      }
    } catch (e) {
      _setLoading(false);
      if (e is Exception) {
        rethrow;
      }
      throw Exception("Network error: $e");
    }
  }

  Future<bool> addExperience(Map<String, dynamic> experienceData) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Student/experiences"),
        headers: _authHeaders,
        body: json.encode(experienceData),
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        // Refresh to get the new ID and data
        await fetchExperiences();
        return true;
      }
      debugPrint("❌ Add Experience Failed: ${response.body}");
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateExperience(int id, Map<String, dynamic> data) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/Student/experiences/$id"),
        headers: _authHeaders,
        body: json.encode(data),
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        await fetchExperiences();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteExperience(int id) async {
    if (_student == null) return false;
    _setLoading(true);

    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/Student/experiences/$id"),
        headers: _authHeaders,
      );
      _setLoading(false);

      if (response.statusCode == 200) {
        // Remove locally
        final updated = _student!.experiences
            .where((e) => e.experienceId != id)
            .toList();
        _student = _student!.copyWith(experiences: updated);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }
}
