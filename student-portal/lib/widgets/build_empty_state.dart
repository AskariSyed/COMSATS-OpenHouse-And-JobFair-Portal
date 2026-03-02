import 'package:flutter/material.dart';

Widget buildEmptyState(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    ),
  );
}
