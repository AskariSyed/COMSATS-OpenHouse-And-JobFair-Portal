import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget buildSocialButton({
  required dynamic icon,
  required Color color,
  required VoidCallback onTap,
  bool isFontAwesome = false,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(50),
    child: Container(
      width: 45,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: isFontAwesome
          ? FaIcon(icon as IconData, color: color, size: 20)
          : Icon(icon as IconData, color: color, size: 22),
    ),
  );
}
