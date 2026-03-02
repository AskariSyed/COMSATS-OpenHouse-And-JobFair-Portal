import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:student_job_fair_portal/screens/sigin.dart';

class StudentSignUpScreen extends StatefulWidget {
  const StudentSignUpScreen({super.key});

  @override
  _StudentSignUpScreenState createState() => _StudentSignUpScreenState();
}

class _StudentSignUpScreenState extends State<StudentSignUpScreen> {
  final TextEditingController regNoController = TextEditingController();
  bool isLoading = false;

  // Note: For Android Emulator use 10.0.2.2, for Real Device/Web use your PC IP
  final String apiUrl = "http://192.168.137.1:5158/api/Auth/student/register";

  // Parse response safely
  Map<String, dynamic> parseResponse(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return {"Message": body};
    }
  }

  Future<void> signUpStudent() async {
    final regNo = regNoController.text.trim();

    if (regNo.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Registration number is required."),
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
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(
            message: "Email Sent Successfully! Please check your email.",
          ),
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
          CustomSnackBar.error(message: "${data['Message']}"),
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
    final isWeb = size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      body: SafeArea(
        child: SizedBox(
          height: size.height,
          width: size.width,
          child: Row(
            children: [
              // Left Side - Blue Section (Only on Web)
              if (isWeb)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            size: 80,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Join Us Today",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Start your journey with COMSATS Job Fair",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // Right Side - Registration Form
              Expanded(
                flex: isWeb ? 1 : 1,
                child: Container(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 60 : 24,
                        vertical: 40,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWeb ? 450 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Mobile Icon
                            if (!isWeb)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1,
                                    size: 60,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            if (!isWeb) const SizedBox(height: 30),
                            Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: isWeb ? 32 : 28,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Enter your university registration number to get started. We'll verify your details and send credentials to your email.",
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Registration Number Field
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
                                labelText: "Registration Number",
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : null,
                                ),
                                hintText: "FA22-BCS-155",
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey.shade600 : null,
                                ),
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xFF2563EB),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 16,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : signUpStudent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
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
                                        "Create Account",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
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
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
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
            ],
          ),
        ),
      ),
    );
  }
}

// Custom formatter to convert to uppercase, insert hyphens, and limit input length
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
