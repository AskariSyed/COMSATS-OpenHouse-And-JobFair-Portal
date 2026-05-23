import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:student_job_fair_portal/screens/sigin.dart';

class StudentSignUpScreen extends StatefulWidget {
  const StudentSignUpScreen({super.key});

  @override
  _StudentSignUpScreenState createState() => _StudentSignUpScreenState();
}

class _StudentSignUpScreenState extends State<StudentSignUpScreen> {
  final TextEditingController regNoController = TextEditingController();
  bool isLoading = false;

  final String apiUrl = "${BackendConfig.apiBaseUrl}/Auth/student/register";

  // Parse response safely
  Map<String, dynamic> parseResponse(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return {"Message": body};
    }
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    final directMessage = data['Message'] ?? data['message'];
    if (directMessage is String && directMessage.trim().isNotEmpty) {
      return directMessage.trim();
    }

    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
        } else if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    final title = data['title'];
    if (title is String && title.trim().isNotEmpty) {
      return title.trim();
    }

    return "Registration failed.";
  }

  Future<void> signUpStudent() async {
    final regNo = regNoController.text.trim();
    final regNoPattern = RegExp(r'^[A-Z]{2}\d{2}-[A-Z]{3}-\d{3}$');

    if (regNo.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Registration number is required."),
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
        body: json.encode({"registrationNo": regNo}),
      );

      final data = parseResponse(response.body);

      if (response.statusCode == 200) {
        final sentToEmail = (data['Email'] ?? data['email'] ?? '')
            .toString()
            .trim();
        final successMessage = sentToEmail.isNotEmpty
            ? "Email sent to:\n$sentToEmail\n\nPlease check your inbox."
            : "Email sent successfully!\nPlease check your inbox.";

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: successMessage),
          displayDuration: const Duration(seconds: 4),
        );

        // Delay slightly to let user read message, then go to login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
            );
          }
        });

        regNoController.clear();
      } else {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: _extractErrorMessage(data)),
        );
      }
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: "Connection Error: $e"),
      );
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
                            crossAxisAlignment: isWeb
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.center,
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
                                'Student Signup',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Create your account and get your credentials sent to your registered email.',
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
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isWeb
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.center,
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
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.school,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!isWeb) const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Create Account',
                                  textAlign: isWeb
                                      ? TextAlign.start
                                      : TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isWeb ? 34 : 28,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  "Enter your registration number and we'll send your account credentials by email.",
                                  textAlign: isWeb
                                      ? TextAlign.start
                                      : TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: subtitleColor,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              TextField(
                                controller: regNoController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9-]'),
                                  ),
                                  UpperCaseHyphenFormatter(maxLength: 12),
                                ],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Registration Number',
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: subtitleColor,
                                  ),
                                  hintText: 'FA22-BCS-155',
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: subtitleColor.withOpacity(0.6),
                                  ),
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

                              const SizedBox(height: 26),

                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : signUpStudent,
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
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Create Account',
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
                                    'Already have an account? ',
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
                                              const StudentLoginScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Sign In',
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
