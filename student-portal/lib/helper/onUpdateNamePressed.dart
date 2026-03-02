import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';

void onUpdateNamePressed(BuildContext context) {
  final student = Provider.of<StudentProvider>(context, listen: false).student;
  final currentName = student?.user.fullName ?? '';
  final nameCtrl = TextEditingController(text: currentName);

  showGenericDialog(
    context: context,
    title: currentName.isEmpty ? "Add Full Name" : "Update Full Name",
    content: TextField(
      controller: nameCtrl,
      decoration: const InputDecoration(
        labelText: "Full Name",
        border: OutlineInputBorder(),
      ),
    ),
    onSave: () async {
      final newName = nameCtrl.text.trim();
      if (newName.isEmpty) throw Exception("Full name cannot be empty.");
      await Provider.of<StudentProvider>(
        context,
        listen: false,
      ).updateFullName(newName);
    },
  );
}
