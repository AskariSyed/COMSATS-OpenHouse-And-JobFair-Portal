import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:student_job_fair_portal/screens/sigin.dart'; // Check your import path

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
        body: json.encode(regNo),
      );

      final data = parseResponse(response.body);

      if (response.statusCode == 200) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(
            message: "Email Sent Successfully! Please check your email.",
          ),
        );
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
        CustomSnackBar.error(message: "Error: $e"),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Consistent background
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 🔹 Web/Desktop Layout (> 800px)
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
                    width: 450, // Fixed width card
                    padding: const EdgeInsets.all(40),
                    child: _buildSignUpForm(),
                  ),
                ),
              ),
            );
          }
          // 🔹 Mobile Layout
          else {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildSignUpForm(),
              ),
            );
          }
        },
      ),
    );
  }

  // 🔹 Reusable Form Widget
  Widget _buildSignUpForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20), // Adjusted spacing
        // 🔹 Header Image
        Image.network(
          "https://media.istockphoto.com/id/1356312511/vector/hr-recruiting-announcement-we-are-hiring-advertisement-human-resources-or-employer-looking.jpg?s=612x612&w=0&k=20&c=MrZc3DimNa24FoVhHrnZbIR29GZqahGMDn3ryfc9OlY=",
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
          "Sign Up",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 40),

        // 🔹 Registration Number Field
        TextField(
          controller: regNoController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
            UpperCaseHyphenFormatter(maxLength: 12),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Registration Number",
            hintText: "Example: FA22-BCS-155",
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),

        const SizedBox(height: 30),

        // 🔹 Sign Up Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : signUpStudent,
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
                    "Sign Up",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // 🔹 Sign In Navigation
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
            );
          },
          child: const Text(
            "Already have an account? Sign In",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
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
    String text = newValue.text.toUpperCase().replaceAll('-', '');

    // Stop input after maxLength (excluding hyphens calculation logic initially)
    // We limit the raw characters to avoid infinite loops,
    // assuming standard format (2 chars + 3 chars + 3 chars = 8 raw chars approx)

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
        formatted += text.substring(7); // last 3 digits
      }
    }

    // Hard limit on final string length to prevent overflow
    if (formatted.length > maxLength) {
      formatted = formatted.substring(0, maxLength);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
