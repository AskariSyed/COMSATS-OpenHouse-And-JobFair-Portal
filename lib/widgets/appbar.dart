import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/sigin.dart';

PreferredSizeWidget buildAppBar(
  BuildContext context,
  StudentProvider provider,
) {
  return AppBar(
    title: const Text(
      'My Profile',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    centerTitle: true,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    actions: [
      IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: 'Edit Profile',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigate to Edit Profile')),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        tooltip: 'Logout',
        onPressed: () {
          provider.logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
            (route) => false,
          );
        },
      ),
    ],
  );
}
