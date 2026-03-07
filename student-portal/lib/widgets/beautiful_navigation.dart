import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:student_job_fair_portal/provider/student_provider.dart';

// Screens
import 'package:student_job_fair_portal/screens/dashboard_screen.dart'; // 🔹 Dashboard
import 'package:student_job_fair_portal/screens/companies_screen.dart';
import 'package:student_job_fair_portal/screens/job_screen.dart';
import 'package:student_job_fair_portal/screens/profile.dart';
import 'package:student_job_fair_portal/screens/queue_screen.dart';
import 'package:student_job_fair_portal/screens/requestScreen.dart';
import 'package:student_job_fair_portal/screens/settings_screen.dart'; // 🔹 Settings
import 'package:student_job_fair_portal/screens/sigin.dart';

// Widgets
import 'package:student_job_fair_portal/widgets/custom_nav_bar.dart'; // For FadePageRoute
import 'package:student_job_fair_portal/widgets/notice_board_popup.dart';

// ============================================================================
// 1. BEAUTIFUL WEB NAVIGATION BAR (Top - Glassmorphism)
// ============================================================================
class BeautifulWebNavBar extends StatelessWidget {
  final String currentRoute;
  final String? profileImageUrl;
  final String userName;

  const BeautifulWebNavBar({
    super.key,
    required this.currentRoute,
    required this.profileImageUrl,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final pendingCount = studentProvider.pendingCompanyRequestCount;
    final upcomingCount = studentProvider.upcomingInterviewCount;
    final requestReminderCount = pendingCount + upcomingCount;

    // 🔹 Theme Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    final dividerColor = Theme.of(context).dividerColor;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 80, // Fixed height
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Glass Effect
          child: Container(
            decoration: BoxDecoration(
              // Dynamic Background Opacity
              color: isDark
                  ? cardColor.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border(
                bottom: BorderSide(
                  color: dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                // 1. Logo Section
                _buildLogo(context, primaryColor, textColor),

                const Spacer(),

                // 2. Navigation Items (Centered)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavBarItem(
                      title: "Dashboard",
                      icon: Icons.dashboard_outlined,
                      isActive: currentRoute == 'Dashboard',
                      onTap: () => _nav(context, const DashboardScreen()),
                    ),
                    const SizedBox(width: 8),
                    _NavBarItem(
                      title: "Profile",
                      icon: Icons.person_outline,
                      isActive: currentRoute == 'Profile',
                      onTap: () => _nav(context, const ProfileScreen()),
                    ),
                    const SizedBox(width: 8),
                    _NavBarItem(
                      title: "Jobs",
                      icon: Icons.work_outline,
                      isActive: currentRoute == 'Jobs',
                      onTap: () => _nav(context, const JobsScreen()),
                    ),
                    const SizedBox(width: 8),
                    _NavBarItem(
                      title: "Companies",
                      icon: Icons.business_outlined,
                      isActive: currentRoute == 'Companies',
                      onTap: () => _nav(context, const CompaniesScreen()),
                    ),
                    const SizedBox(width: 8),
                    _NavBarItem(
                      title: "Interviews",
                      icon: Icons.list_alt_outlined,
                      isActive: currentRoute == 'Interviews',
                      badgeCount: upcomingCount,
                      onTap: () => _nav(context, const QueueScreen()),
                    ),
                    const SizedBox(width: 8),
                    _NavBarItem(
                      title: "Requests",
                      icon: Icons.inbox_outlined,
                      isActive: currentRoute == 'Requests',
                      badgeCount: requestReminderCount,
                      onTap: () => _nav(context, const RequestsScreen()),
                    ),
                  ],
                ),

                const Spacer(),

                // 3. Profile, Settings & Logout Section
                _buildUserProfile(context, primaryColor, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget page) {
    // Don't navigate if already on the page (simple string check)
    if (currentRoute == page.toString()) return;
    Navigator.pushReplacement(context, FadePageRoute(page: page));
  }

  Widget _buildLogo(BuildContext context, Color primary, Color text) {
    return Row(
      children: [
        Image.asset(
          'assets/LogoWithoutBg.png',
          height: 40,
          errorBuilder: (_, __, ___) => Icon(Icons.school, color: primary),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "COMSATS",
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "Job Fair Student Portal",
              style: TextStyle(
                color: text.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserProfile(BuildContext context, Color primary, Color text) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: text,
              ),
            ),
            Text(
              "Student",
              style: TextStyle(
                color: text.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(
            context,
          ).dividerColor.withValues(alpha: 0.1),
          backgroundImage: profileImageUrl != null
              ? NetworkImage(profileImageUrl!)
              : null,
          child: profileImageUrl == null
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 8),

        // 🔹 Notice Board Button (Web)
        IconButton(
          onPressed: () => showNoticeBoardPopup(context),
          icon: Icon(
            Icons.campaign_outlined,
            color: text.withValues(alpha: 0.6),
          ),
          tooltip: "Notice Board",
        ),

        // 🔹 Settings Button (Web)
        IconButton(
          onPressed: () {
            if (currentRoute == 'Settings') return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          icon: Icon(Icons.settings, color: text.withValues(alpha: 0.6)),
          tooltip: "Settings",
        ),

        // Logout Button
        IconButton(
          onPressed: () async {
            await Provider.of<StudentProvider>(context, listen: false).logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
                (route) => false,
              );
            }
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          tooltip: "Logout",
        ),
      ],
    );
  }
}

// Helper Widget for Web Nav Items with Hover Effect
class _NavBarItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.title,
    required this.icon,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final inactiveColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final activeBg = primary.withValues(alpha: 0.15);
    final hoverBg = Theme.of(context).hoverColor;

    final fgColor = widget.isActive || _isHovered ? primary : inactiveColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeBg
                : _isHovered
                ? hoverBg
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: fgColor),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: widget.isActive
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (widget.badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. BEAUTIFUL MOBILE NAVIGATION BAR (Floating Bottom)
// ============================================================================
class BeautifulMobileNavBar extends StatelessWidget {
  final int currentIndex;

  const BeautifulMobileNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final reminderCount =
        studentProvider.pendingCompanyRequestCount +
        studentProvider.upcomingInterviewCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Float it
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: isDark
            ? Border.all(color: Colors.grey.shade800, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: cardColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: false, // Cleaner look
          showUnselectedLabels: false,
          elevation: 0,
          onTap: (index) => _handleNavigation(context, index),
          items: [
            _buildItem(
              context,
              Icons.dashboard,
              Icons.dashboard_outlined,
              "Dashboard",
              0,
            ),
            _buildItem(
              context,
              Icons.person,
              Icons.person_outline,
              "Profile",
              1,
            ),
            _buildItem(context, Icons.work, Icons.work_outline, "Jobs", 2),
            _buildItem(
              context,
              Icons.business,
              Icons.business_outlined,
              "Companies",
              3,
            ),
            _buildItem(
              context,
              Icons.list_alt,
              Icons.list_alt_outlined,
              "Interviews",
              4,
            ),
            _buildItem(
              context,
              Icons.inbox,
              Icons.inbox_outlined,
              "Requests",
              5,
              badgeCount: reminderCount,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildItem(
    BuildContext context,
    IconData active,
    IconData inactive,
    String label,
    int index, {
    int badgeCount = 0,
  }) {
    return BottomNavigationBarItem(
      icon: _AnimatedIcon(
        activeIcon: active,
        inactiveIcon: inactive,
        isSelected: currentIndex == index,
        badgeCount: badgeCount,
      ),
      label: label,
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const DashboardScreen();
        break;
      case 1:
        nextScreen = const ProfileScreen();
        break;
      case 2:
        nextScreen = const JobsScreen();
        break;
      case 3:
        nextScreen = const CompaniesScreen();
        break;
      case 4:
        nextScreen = const QueueScreen();
        break;
      case 5:
        nextScreen = const RequestsScreen();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(context, FadePageRoute(page: nextScreen));
  }
}

class _AnimatedIcon extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isSelected;
  final int badgeCount;

  const _AnimatedIcon({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.isSelected,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final iconColor =
        Theme.of(context).iconTheme.color?.withValues(alpha: 0.5) ??
        Colors.grey;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? activeIcon : inactiveIcon,
            size: 24,
            color: isSelected ? primaryColor : iconColor,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
