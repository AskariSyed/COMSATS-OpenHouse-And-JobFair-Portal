import 'package:flutter/material.dart';

Widget buildBottomNav(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: (index) {},
    selectedItemColor: Theme.of(context).primaryColor,
    unselectedItemColor: Colors.grey.shade500,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_outlined),
        activeIcon: Icon(Icons.list_alt),
        label: 'Queue',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.business_outlined),
        activeIcon: Icon(Icons.business),
        label: 'Companies',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inbox_outlined),
        activeIcon: Icon(Icons.inbox),
        label: 'Requests',
      ),
    ],
  );
}
