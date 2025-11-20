import 'package:flutter/material.dart';

Future<void> selectDate(
  BuildContext context,
  TextEditingController controller,
) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1950),
    lastDate: DateTime(2101),
    builder: (context, child) {
      // Optional: Custom styling for the picker (often needed for dark modes)
      return Theme(
        data:
            ThemeData.light(), // Use light theme for the picker if main app is dark
        child: child!,
      );
    },
  );
  if (picked != null) {
    // Format to YYYY-MM-DD string
    controller.text = picked.toIso8601String().split('T').first;
  }
}
