import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/screens/job_screen.dart';
import 'package:student_job_fair_portal/screens/profile.dart';
import 'package:student_job_fair_portal/screens/queue_screen.dart';
import 'package:student_job_fair_portal/screens/requestScreen.dart';
import 'package:student_job_fair_portal/widgets/custom_nav_bar.dart'; // Import the new route

Widget buildBottomNav(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Theme.of(context).primaryColor,
    unselectedItemColor: Colors.grey.shade600,
    showUnselectedLabels: true,
    onTap: (index) {
      if (index == currentIndex) return;

      Widget nextScreen;
      switch (index) {
        case 0:
          nextScreen = const ProfileScreen();
          break;
        case 1:
          nextScreen = const JobsScreen();
          break;
        case 3:
          nextScreen = const QueueScreen();
          break;
        case 2:
          nextScreen = const CompaniesScreen();
          break;
        case 4: // Requests is index 4 based on your items list
          nextScreen = const RequestsScreen();
          break;
        default:
          return;
      }

      // Use FadePageRoute for smooth transition
      Navigator.pushReplacement(context, FadePageRoute(page: nextScreen));
    },
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.work_outline),
        activeIcon: Icon(Icons.work),
        label: 'Jobs',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.business_outlined),
        activeIcon: Icon(Icons.business),
        label: 'Companies',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_outlined),
        activeIcon: Icon(Icons.list_alt),
        label: 'Queue',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inbox_outlined),
        activeIcon: Icon(Icons.inbox),
        label: 'Requests',
      ),
    ],
  );
}
