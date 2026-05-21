import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:student_job_fair_portal/model/student.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/forgetpassword_screen.dart'
    deferred as forgot_password_screen;
import 'package:student_job_fair_portal/screens/dashboard_screen.dart'
    deferred as dashboard_screen;
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:student_job_fair_portal/screens/signup.dart'
    deferred as signup_screen;
import 'package:url_launcher/url_launcher.dart';
import 'package:student_job_fair_portal/utils/web_file_downloader.dart';

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
  final String apiUrl = "${BackendConfig.apiBaseUrl}/Auth/student/login";
  static const String _apkDownloadUrl = String.fromEnvironment(
    'STUDENT_APK_URL',
    defaultValue: 'https://student.jfair.tech/downloads/student-portal.apk',
  );

  String _friendlyLoginError(Object error) {
    final message = error.toString();

    if (message.contains('SocketException') ||
        message.contains('Failed host lookup') ||
        message.contains('NetworkException') ||
        message.contains('XMLHttpRequest error') ||
        message.contains('ClientException')) {
      return 'Cannot connect to server. Please check your internet, API URL, and CORS/proxy setup.';
    }

    if (message.contains('TimeoutException')) {
      return 'Connection timeout. Server is not responding.';
    }

    if (message.contains('HandshakeException')) {
      return 'Secure connection failed. Please check SSL/HTTPS configuration.';
    }

    if (error is FormatException ||
        message.contains('type') ||
        message.contains('NoSuchMethodError')) {
      return 'Login succeeded but response parsing failed. Please refresh and try again.';
    }

    if (message.contains('loadLibrary')) {
      return 'Login succeeded but app resources failed to load. Please hard refresh the page (Ctrl+F5).';
    }

    return 'Login failed unexpectedly. Please try again.';
  }

  Future<void> _openApkDownload() async {
    final uri = Uri.tryParse(_apkDownloadUrl);
    if (uri == null) return;

    if (kIsWeb) {
      WebFileDownloader.downloadFromUrl(_apkDownloadUrl, 'student-portal.apk');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
          message: 'Unable to open APK download link.',
        ),
      );
    }
  }

  Future<void> loginStudent() async {
    final regNo = regNoController.text.trim();
    final password = passController.text.trim();
    final regNoPattern = RegExp(r'^[A-Z]{2}\d{2}-[A-Z]{3}-\d{3}$');

    if (regNo.isEmpty || password.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(message: "Please fill all fields"),
      );
      return;
    }

    if (!regNoPattern.hasMatch(regNo)) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
          message: "Use format AA00-AAA-000 (e.g. FA22-BCS-007).",
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"emailOrRegNo": regNo, "password": password}),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid login response shape');
        }
        final data = decoded;

        final token = (data['token'] ?? '').toString();
        if (token.isEmpty) {
          throw const FormatException('Missing token in login response');
        }

        final studentJson = (data['student'] is Map<String, dynamic>)
            ? data['student'] as Map<String, dynamic>
            : <String, dynamic>{};
        final loggedInStudent = Student.fromJson(studentJson);

        if (mounted) {
          Provider.of<StudentProvider>(context, listen: false)
            ..setToken(token)
            ..setStudent(loggedInStudent);

          // Fetch extra data for profile cards immediately.
          final isProfileComplete =
              data['profileComplete'] == true ||
              data['ProfileComplete'] == true;
          if (isProfileComplete) {
            Provider.of<StudentProvider>(context, listen: false).fetchProfile();
          }

          // Run FCM setup in the background without blocking the UI navigation
          _setupFCMAfterLogin(token);

          await dashboard_screen.loadLibrary();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => dashboard_screen.DashboardScreen(),
              ),
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
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
        debugPrint('$stackTrace');
      }

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: _friendlyLoginError(e)),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _setupFCMAfterLogin(String authToken) async {
    try {
      String? fcmToken;
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kIsWeb) {
          const vapidKey = String.fromEnvironment(
            'FIREBASE_VAPID_KEY',
            defaultValue:
                'BF03FtvADQR8PrW4u7iYfaYnZdiU6tsXAxZTPRrVVb9HQ115gpq89FAUmIzp_NFh7PBYO2AW0UbmO-leT5g2V6s',
          );
          fcmToken = await _firebaseMessaging.getToken(vapidKey: vapidKey);
        } else {
          fcmToken = await _firebaseMessaging.getToken();
        }
      }

      if (fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("fcmToken", fcmToken);

        final registerUrl =
            "${BackendConfig.apiBaseUrl}/Student/register-fcm-token";
        await http.post(
          Uri.parse(registerUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $authToken",
          },
          body: json.encode({"token": fcmToken}),
        );
        if (kDebugMode) print("✅ FCM Token registered in background.");
      } else {
        if (kDebugMode) print("⚠️ FCM Token is null or permission denied.");
      }
    } catch (e) {
      if (kDebugMode) print("FCM Background Error: $e");
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
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : brandNavy;
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : Colors.blueGrey.shade600;
    final fieldFill = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8FAFC);
    final fieldBorder = isDark
        ? const Color(0xFF475569)
        : const Color(0xFFD1D9E6);

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
                                    height: 70,
                                    width: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.transparent,
                                    ),
                                    child: Image.asset(
                                      'assets/LogoWithoutBg.png',
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      isAntiAlias: true,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.school,
                                        color: Colors.white,
                                        size: 70,
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
                                color: isDark
                                    ? const Color(0x22000000)
                                    : const Color(0x1A0F172A),
                                blurRadius: 32,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: isWeb
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.center,
                              children: [
                                if (!isWeb)
                                  Center(
                                    child: SizedBox(
                                      height: 74,
                                      width: 74,
                                      child: Image.asset(
                                        'assets/LogoWithoutBg.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                        isAntiAlias: true,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.school,
                                          color: titleColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!isWeb) const SizedBox(height: 20),
                                Text(
                                  'Welcome Back',
                                  textAlign: isWeb
                                      ? TextAlign.start
                                      : TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue to your student dashboard.',
                                  textAlign: isWeb
                                      ? TextAlign.start
                                      : TextAlign.center,
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
                                      borderSide: BorderSide(
                                        color: fieldBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: fieldBorder,
                                      ),
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
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : Colors.blueGrey.shade400,
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
                                      borderSide: BorderSide(
                                        color: fieldBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: fieldBorder,
                                      ),
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
                                      () async {
                                        await forgot_password_screen
                                            .loadLibrary();
                                        if (!context.mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                forgot_password_screen.ForgotPasswordRequestScreen(),
                                          ),
                                        );
                                      }();
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
                                const SizedBox(height: 14),
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
                                        () async {
                                          await signup_screen.loadLibrary();
                                          if (!context.mounted) return;
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  signup_screen.StudentSignUpScreen(),
                                            ),
                                          );
                                        }();
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
                                if (kIsWeb)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: _openApkDownload,
                                      icon: const Icon(Icons.android, size: 16),
                                      label: const Text(
                                        'APK',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: subtitleColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        minimumSize: const Size(0, 30),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.blue.shade900.withOpacity(0.3)
                                        : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.blue.shade700.withOpacity(
                                              0.5,
                                            )
                                          : Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    '📚 Disclaimer: This is a Final Year Project by COMSATS Students (Class of 2026) Currently in Beta Testing.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.blue.shade200
                                          : Colors.blue.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
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

// Strict formatter for AA00-AAA-000
class UpperCaseHyphenFormatter extends TextInputFormatter {
  final int maxLength;
  UpperCaseHyphenFormatter({required this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawInput = newValue.text.toUpperCase().replaceAll('-', '');
    final buffer = StringBuffer();

    for (final char in rawInput.split('')) {
      final index = buffer.length;
      if (index >= 10) break;

      final isLetter = RegExp(r'[A-Z]').hasMatch(char);
      final isDigit = RegExp(r'\d').hasMatch(char);

      final shouldBeLetter = index < 2 || (index >= 4 && index <= 6);
      final shouldBeDigit = (index >= 2 && index <= 3) || index >= 7;

      if ((shouldBeLetter && isLetter) || (shouldBeDigit && isDigit)) {
        buffer.write(char);
      }
    }

    final filtered = buffer.toString();
    final formatted = StringBuffer();

    for (int i = 0; i < filtered.length; i++) {
      if (i == 4 || i == 7) formatted.write('-');
      formatted.write(filtered[i]);
    }

    String result = formatted.toString();
    if (result.length > maxLength) {
      result = result.substring(0, maxLength);
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
