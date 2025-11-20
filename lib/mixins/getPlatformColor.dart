import 'dart:ui';

import 'package:flutter/material.dart';

Color getPlatformColor(String platform) {
  final p = platform.toLowerCase();

  if (p.contains('github')) return Colors.black;
  if (p.contains('linkedin')) return const Color(0xFF0077B5);
  if (p.contains('twitter')) return const Color(0xFF1DA1F2);
  if (p.contains('facebook')) return const Color(0xFF1877F2);
  if (p.contains('instagram')) return const Color(0xFFC13584);
  if (p.contains('youtube')) return const Color(0xFFFF0000);
  if (p.contains('website')) return Colors.green;
  if (p.contains('stack')) return const Color(0xFFFE7A16);
  if (p.contains('medium')) return Colors.black;
  if (p.contains('dev')) return Colors.black;
  if (p.contains('twitch')) return const Color(0xFF9146FF);
  if (p.contains('reddit')) return const Color(0xFFFF4500);
  if (p.contains('pinterest')) return const Color(0xFFE60023);
  if (p.contains('quora')) return const Color(0xFFB92B27);
  if (p.contains('slack')) return const Color(0xFF4A154B);

  return Colors.blueGrey;
}
