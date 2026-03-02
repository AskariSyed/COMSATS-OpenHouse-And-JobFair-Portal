import 'package:flutter/material.dart';

Future<void> selectDate(
  BuildContext context,
  TextEditingController controller,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Try to parse existing date from controller
  DateTime initialDate = DateTime.now();
  if (controller.text.isNotEmpty) {
    try {
      initialDate = DateTime.parse(controller.text);
    } catch (_) {
      initialDate = DateTime.now();
    }
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1950),
    lastDate: DateTime(2101),
    builder: (context, child) {
      return Theme(
        data: isDark
            ? ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: Colors.blue.shade400,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
              )
            : ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blue.shade600,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
              ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    // Format to YYYY-MM-DD string
    controller.text = picked.toIso8601String().split('T').first;
  }
}
