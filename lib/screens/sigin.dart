import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for InputFormatters
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:student_job_fair_portal/model/student.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/profile.dart';
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
      // 🔹 Get FCM Token
      String? fcmToken;
      try {
        fcmToken = await _firebaseMessaging.getToken();
      } catch (e) {
        if (kDebugMode) print("FCM Error: $e");
      }

      // 🔹 API Call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "emailOrRegNo": regNo, // Sending RegNo
          "password": password,
          "fcmToken": fcmToken,
        }),
      );

      if (kDebugMode) print("Login Response: ${response.body}");

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

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (data['profileComplete'] == true) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            }
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
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "Error: $e"),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 450,
                    padding: const EdgeInsets.all(40),
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            );
          } else {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildLoginForm(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        // 🔹 Header Image
        Image.asset(
          "lib/assets/StudentJobFairPortalLogo.png",
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.image_not_supported,
            size: 100,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          "CUI JOB FAIR",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          "Welcome Back",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 40),

        // 🔹 Registration Number Field (Formatted)
        TextField(
          controller: regNoController,
          // 🔹 APPLYING FORMATTERS HERE
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
            UpperCaseHyphenFormatter(maxLength: 12),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Registration Number",
            hintText: "FA22-BCS-155",
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),

        const SizedBox(height: 20),

        // 🔹 Password Field
        TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Password",
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),

        const SizedBox(height: 30),

        // 🔹 Login Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : loginStudent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                    "Log In",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // 🔹 Sign Up Navigation
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentSignUpScreen()),
            );
          },
          child: const Text("Don’t have an account? Sign Up"),
        ),
      ],
    );
  }
}

// 🔹 Helper Class for Formatting (Same as SignUp)
class UpperCaseHyphenFormatter extends TextInputFormatter {
  final int maxLength;
  UpperCaseHyphenFormatter({required this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase().replaceAll('-', '');

    if (text.length > maxLength) text = text.substring(0, maxLength);

    String formatted = '';
    if (text.length >= 2) {
      formatted += text.substring(0, 2); // FA or SP
      if (text.length >= 4) {
        formatted += text.substring(2, 4); // year
      } else if (text.length > 2) {
        formatted += text.substring(2);
      }
      formatted += '-';
    } else {
      formatted = text;
    }

    if (text.length > 4) {
      if (text.length >= 7) {
        formatted += text.substring(4, 7); // program code
      } else {
        formatted += text.substring(4);
      }
      if (text.length > 7) {
        formatted += '-';
        formatted += text.substring(7); // last digits
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
