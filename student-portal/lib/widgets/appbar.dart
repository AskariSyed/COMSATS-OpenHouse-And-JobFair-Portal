import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
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
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.info(message: 'Navigate to Edit Profile'),
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
