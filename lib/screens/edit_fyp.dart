import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';

class EditFypScreen extends StatefulWidget {
  const EditFypScreen({super.key});

  @override
  State<EditFypScreen> createState() => _EditFypScreenState();
}

class _EditFypScreenState extends State<EditFypScreen> {
  late TextEditingController titleController;
  late TextEditingController demoController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    final student = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).student;
    titleController = TextEditingController(text: student?.fypTitle ?? "");
    demoController = TextEditingController(text: student?.fypDemoUrl ?? "");
    descriptionController = TextEditingController(
      text: student?.fypDescription ?? "",
    );
  }

  Future<void> _saveFyp() async {
    final provider = Provider.of<StudentProvider>(context, listen: false);

    if (provider.token == null) return;

    final uri = Uri.parse("http://192.168.137.1:5158/api/Student/fyp");

    final body = {
      "fypTitle": titleController.text.trim(),
      "fypDemoUrl": demoController.text.trim(),
      "fypDescription": descriptionController.text.trim(),
    };

    final response = await http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${provider.token}",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Update local student object
      final student = provider.student;
      provider.setStudent(
        student!.copyWith(
          fypTitle: body["fypTitle"],
          fypDemoUrl: body["fypDemoUrl"],
          fypDescription: body["fypDescription"],
        ),
      );

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: "✅ FYP updated successfully"),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "❌ Failed to update FYP"),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit FYP Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "FYP Title",
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: demoController,
              decoration: const InputDecoration(
                labelText: "FYP Demo URL",
                prefixIcon: Icon(Icons.smart_display),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "FYP Description",
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _saveFyp,
              icon: const Icon(Icons.save),
              label: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
