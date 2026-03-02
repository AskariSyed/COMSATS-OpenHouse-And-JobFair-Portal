import 'package:collapsible_sidebar/collapsible_sidebar/collapsible_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/sigin.dart';

List<CollapsibleItem> generateSidebarItems(
  BuildContext context,
  void Function(void Function()) setState,
  String currentRoute,
) {
  return [
    CollapsibleItem(
      text: 'Profile',
      icon: Icons.person_outline,
      onPressed: () => setState(() => currentRoute = 'Profile'),
      isSelected: true,
    ),
    CollapsibleItem(
      text: 'Queue',
      icon: Icons.list_alt_outlined,
      onPressed: () => setState(() => currentRoute = 'Queue'),
    ),
    CollapsibleItem(
      text: 'Companies',
      icon: Icons.business_outlined,
      onPressed: () => setState(() => currentRoute = 'Companies'),
    ),
    CollapsibleItem(
      text: 'Requests',
      icon: Icons.inbox_outlined,
      onPressed: () => setState(() => currentRoute = 'Requests'),
    ),
    CollapsibleItem(
      text: 'Jobs',
      icon: Icons.work_outline_sharp,
      onPressed: () => setState(() => currentRoute = 'Jobs'),
    ),
    CollapsibleItem(
      text: 'Logout',
      icon: Icons.logout,
      onPressed: () {
        Provider.of<StudentProvider>(context, listen: false).logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
          (route) => false,
        );
      },
    ),
  ];
}
