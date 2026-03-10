import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:student_job_fair_portal/model/student.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/forgetpassword_screen.dart';
import 'package:student_job_fair_portal/screens/dashboard_screen.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:student_job_fair_portal/screens/signup.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  _StudentLoginScreenState createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordVisible = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final String apiUrl = "http://192.168.137.1:5158/api/Auth/student/login";

  Future<void> loginStudent() async {
    final regNo = regNoController.text.trim();
    final password = passController.text.trim();

    if (regNo.isEmpty || password.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: "Please fill all fields"),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? fcmToken;
      try {
        if (kIsWeb) {
          // Request permission first for web
          NotificationSettings settings = await _firebaseMessaging
              .requestPermission(alert: true, badge: true, sound: true);

          if (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) {
            // Get token for web browsers (Chrome, Firefox, Safari, etc.)
            fcmToken = await _firebaseMessaging.getToken();
            if (kDebugMode) {
              print("🔑 Web FCM Token: ${fcmToken?.substring(0, 20)}...");
            }
          } else {
            if (kDebugMode) print("⚠️ Notification permission denied on web");
          }
        } else {
          // Mobile platforms
          fcmToken = await _firebaseMessaging.getToken();
        }
      } catch (e) {
        if (kDebugMode) print("FCM Error: $e");
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "emailOrRegNo": regNo,
          "password": password,
          "fcmToken": fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("fcmToken", fcmToken);
        }

        final studentJson = data['student'] ?? {};
        final loggedInStudent = Student.fromJson(studentJson);

        if (mounted) {
          Provider.of<StudentProvider>(context, listen: false)
            ..setToken(data['token'])
            ..setStudent(loggedInStudent);

          // Fetch extra data for profile cards immediately.
          final isProfileComplete =
              data['profileComplete'] == true || data['ProfileComplete'] == true;
          if (isProfileComplete) {
            Provider.of<StudentProvider>(context, listen: false).fetchProfile();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          });
        }
      } else {
        String errorMsg;
        try {
          final data = json.decode(response.body);
          errorMsg = data['Message'] ?? response.body;
        } catch (_) {
          errorMsg = response.body;
        }

        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: errorMsg),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('NetworkException')) {
          errorMessage =
              "Cannot connect to server. Please check your internet connection or try again later.";
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = "Connection timeout. Server is not responding.";
        } else if (e.toString().contains('HandshakeException')) {
          errorMessage =
              "Secure connection failed. Please check your network settings.";
        } else {
          errorMessage = "Unable to connect to server. Please try again later.";
        }

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: errorMessage),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width >= 980;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandBlue = Color(0xFF2563EB);
    const brandNavy = Color(0xFF0F172A);
    final pageBg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : brandNavy;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600;
    final fieldFill = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final fieldBorder = isDark ? const Color(0xFF475569) : const Color(0xFFD1D9E6);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SizedBox(
          height: size.height,
          width: size.width,
          child: Row(
            children: [
              if (isWeb)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0B1220),
                          Color(0xFF1E3A8A),
                          Color(0xFF2563EB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -80,
                          left: -60,
                          child: Container(
                            height: 260,
                            width: 260,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -100,
                          right: -70,
                          child: Container(
                            height: 320,
                            width: 320,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 56,
                            vertical: 42,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 54,
                                    width: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                    child: Image.asset(
                                      'assets/LogoWithoutBg.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.school,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Text(
                                      'COMSATS Wah Job Fair',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Text(
                                'Student Portal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Secure sign-in for registrations, profile updates, and interview readiness.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.86),
                                  fontSize: 17,
                                  height: 1.45,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Designed for the Open House and Job Fair experience.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  color: pageBg,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 54 : 20,
                        vertical: 30,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWeb ? 480 : 500,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 30 : 22,
                            vertical: isWeb ? 30 : 24,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? const Color(0x22000000) : const Color(0x1A0F172A),
                                blurRadius: 32,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isWeb)
                                  Center(
                                    child: Container(
                                      height: 74,
                                      width: 74,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [brandNavy, brandBlue],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        'assets/LogoWithoutBg.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.school,
                                              color: Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                if (!isWeb) const SizedBox(height: 20),
                                Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue to your student dashboard.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: subtitleColor,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                TextField(
                                  controller: regNoController,
                                  autofillHints: const [AutofillHints.username],
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9-]'),
                                    ),
                                    UpperCaseHyphenFormatter(maxLength: 12),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Registration Number',
                                    hintText: 'FA22-BCS-155',
                                    prefixIcon: const Icon(
                                      Icons.badge_outlined,
                                      color: brandBlue,
                                    ),
                                    filled: true,
                                    fillColor: fieldFill,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: brandBlue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: passController,
                                  obscureText: !_isPasswordVisible,
                                  autofillHints: const [AutofillHints.password],
                                  enableSuggestions: true,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    TextInput.finishAutofillContext();
                                    if (!isLoading) loginStudent();
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: brandBlue,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400,
                                      ),
                                      onPressed: () => setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: fieldFill,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: brandBlue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordRequestScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: brandBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            TextInput.finishAutofillContext();
                                            loginStudent();
                                          },
                                    style:
                                        ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                          elevation: 0,
                                        ).copyWith(
                                          backgroundColor:
                                              WidgetStateProperty.all(
                                                Colors.transparent,
                                              ),
                                        ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [brandNavy, brandBlue],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 15,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const StudentSignUpScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: brandBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

// Keep your Helper Class for Formatting
class UpperCaseHyphenFormatter extends TextInputFormatter {
  final int maxLength;
  UpperCaseHyphenFormatter({required this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Handle deletion - if user is deleting, preserve the operation
    if (newValue.text.length < oldValue.text.length) {
      // User is deleting
      String newText = newValue.text.toUpperCase();
      int cursorPos = newValue.selection.baseOffset;

      // If cursor is right after a hyphen that was auto-added, move it back
      if (cursorPos > 0 &&
          cursorPos < newText.length &&
          newText[cursorPos] == '-') {
        cursorPos--;
      }

      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos),
      );
    }

    // Handle addition/typing
    String text = newValue.text.toUpperCase().replaceAll('-', '');
    if (text.length > maxLength) text = text.substring(0, maxLength);

    String formatted = '';
    if (text.length >= 2) {
      formatted += text.substring(0, 2);
      if (text.length >= 4) {
        formatted += text.substring(2, 4);
      } else if (text.length > 2) {
        formatted += text.substring(2);
      }
      formatted += '-';
    } else {
      formatted = text;
    }

    if (text.length > 4) {
      if (text.length >= 7) {
        formatted += text.substring(4, 7);
      } else {
        formatted += text.substring(4);
      }
      if (text.length > 7) {
        formatted += '-';
        formatted += text.substring(7);
      }
    }

    if (formatted.length > maxLength) {
      formatted = formatted.substring(0, maxLength);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
