import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1250;
                final isUltraCompact = constraints.maxWidth < 1020;
                final isVerySmall = constraints.maxWidth < 880;
                final showNavLabels = constraints.maxWidth >= 1360;
                final showSecondaryActions = constraints.maxWidth >= 1120;
                final navLabelMode = showNavLabels
                    ? _NavLabelMode.full
                    : isVerySmall
                    ? _NavLabelMode.hidden
                    : _NavLabelMode.compact;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isUltraCompact ? 14 : (isCompact ? 20 : 40),
                  ),
                  child: Row(
                    children: [
                      // 1. Logo Section
                      _buildLogo(
                        context,
                        primaryColor,
                        textColor,
                        compact: isCompact,
                      ),

                      const SizedBox(width: 10),

                      // 2. Navigation Items (center area is scroll-safe)
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _NavBarItem(
                                  title: "Dashboard",
                                  icon: Icons.dashboard_outlined,
                                  isActive: currentRoute == 'Dashboard',
                                  labelMode: navLabelMode,
                                  onTap: () =>
                                      _nav(context, const DashboardScreen()),
                                ),
                                const SizedBox(width: 8),
                                _NavBarItem(
                                  title: "Profile",
                                  icon: Icons.person_outline,
                                  isActive: currentRoute == 'Profile',
                                  labelMode: navLabelMode,
                                  onTap: () =>
                                      _nav(context, const ProfileScreen()),
                                ),
                                const SizedBox(width: 8),
                                _NavBarItem(
                                  title: "Jobs",
                                  icon: Icons.work_outline,
                                  isActive: currentRoute == 'Jobs',
                                  labelMode: navLabelMode,
                                  onTap: () =>
                                      _nav(context, const JobsScreen()),
                                ),
                                const SizedBox(width: 8),
                                _NavBarItem(
                                  title: "Companies",
                                  icon: Icons.business_outlined,
                                  isActive: currentRoute == 'Companies',
                                  labelMode: navLabelMode,
                                  onTap: () =>
                                      _nav(context, const CompaniesScreen()),
                                ),
                                const SizedBox(width: 8),
                                _NavBarItem(
                                  title: "Interviews",
                                  icon: Icons.list_alt_outlined,
                                  isActive: currentRoute == 'Interviews',
                                  badgeCount: upcomingCount,
                                  labelMode: navLabelMode,
                                  onTap: () =>
                                      _nav(context, const QueueScreen()),
                                ),
                                const SizedBox(width: 8),
                                _NavBarItem(
                                  title: "Requests",
                                  icon: Icons.inbox_outlined,
                                  isActive: currentRoute == 'Requests',
                                  badgeCount: requestReminderCount,
                                  labelMode: navLabelMode,
                                  onTap: () =>
                                      _nav(context, const RequestsScreen()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 3. Profile, Settings & Logout Section
                      _buildUserProfile(
                        context,
                        primaryColor,
                        textColor,
                        compact: isUltraCompact,
                        showSecondaryActions: showSecondaryActions,
                      ),
                    ],
                  ),
                );
              },
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

  Widget _buildLogo(
    BuildContext context,
    Color primary,
    Color text, {
    bool compact = false,
  }) {
    return Row(
      children: [
        Image.asset(
          'assets/LogoWithoutBg.png',
          height: compact ? 34 : 40,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Icon(Icons.school, color: primary),
        ),
        if (!compact) ...[
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
      ],
    );
  }

  Widget _buildUserProfile(
    BuildContext context,
    Color primary,
    Color text, {
    bool compact = false,
    bool showSecondaryActions = true,
  }) {
    return Row(
      children: [
        if (!compact) ...[
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
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (currentRoute == 'Profile') return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: compact ? 34 : 40,
              height: compact ? 34 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              child: profileImageUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profileImageUrl!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : "U",
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        if (showSecondaryActions)
          IconButton(
            onPressed: () => showNoticeBoardPopup(context),
            icon: Icon(
              Icons.campaign_outlined,
              color: text.withValues(alpha: 0.6),
            ),
            tooltip: "Notice Board",
          ),

        if (showSecondaryActions)
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

enum _NavLabelMode { full, compact, hidden }

// Helper Widget for Web Nav Items with Hover Effect
class _NavBarItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final int badgeCount;
  final _NavLabelMode labelMode;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.title,
    required this.icon,
    required this.isActive,
    this.badgeCount = 0,
    this.labelMode = _NavLabelMode.full,
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
    final showLabel = widget.labelMode != _NavLabelMode.hidden;
    final isCompactLabel = widget.labelMode == _NavLabelMode.compact;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 14 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeBg
                : _isHovered
                ? hoverBg
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isCompactLabel
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(widget.icon, size: 20, color: fgColor),
                        if (widget.badgeCount > 0)
                          Positioned(
                            right: -10,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              constraints: const BoxConstraints(minWidth: 16),
                              child: Text(
                                widget.badgeCount > 99
                                    ? '99+'
                                    : '${widget.badgeCount}',
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fgColor,
                        fontWeight: widget.isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 11,
                        height: 1.05,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 20, color: fgColor),
                    if (showLabel) ...[
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
                    ],
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
                          widget.badgeCount > 99
                              ? '99+'
                              : '${widget.badgeCount}',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomSpacing = (screenWidth * 0.01).clamp(6.0, 10.0);
    final navHorizontalMargin = (screenWidth * 0.04).clamp(12.0, 20.0);
    final navVerticalPadding = (screenWidth * 0.005).clamp(0.0, 2.0);
    final navRadius = (screenWidth * 0.065).clamp(20.0, 26.0);
    final navBarHeight = (screenWidth * 0.135).clamp(54.0, 60.0);
    final iconSize = (screenWidth * 0.06).clamp(20.0, 24.0);
    final iconPadding = (screenWidth * 0.016).clamp(4.0, 6.0);

    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: EdgeInsets.only(bottom: bottomSpacing),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          navHorizontalMargin,
          0,
          navHorizontalMargin,
          0,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(navRadius),
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
          borderRadius: BorderRadius.circular(navRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: navVerticalPadding),
            child: SizedBox(
              height: navBarHeight,
              child: Row(
                children: [
                  _buildItem(
                    context,
                    Icons.dashboard,
                    Icons.dashboard_outlined,
                    "Dashboard",
                    0,
                    iconSize: iconSize,
                    iconPadding: iconPadding,
                  ),
                  _buildItem(
                    context,
                    Icons.person,
                    Icons.person_outline,
                    "Profile",
                    1,
                    iconSize: iconSize,
                    iconPadding: iconPadding,
                  ),
                  _buildItem(
                    context,
                    Icons.work,
                    Icons.work_outline,
                    "Jobs",
                    2,
                    iconSize: iconSize,
                    iconPadding: iconPadding,
                  ),
                  _buildItem(
                    context,
                    Icons.business,
                    Icons.business_outlined,
                    "Companies",
                    3,
                    iconSize: iconSize,
                    iconPadding: iconPadding,
                  ),
                  _buildItem(
                    context,
                    Icons.list_alt,
                    Icons.list_alt_outlined,
                    "Interviews",
                    4,
                    badgeCount: studentProvider.upcomingInterviewCount,
                    iconSize: iconSize,
                    iconPadding: iconPadding,
                  ),
                  _buildItem(
                    context,
                    Icons.inbox,
                    Icons.inbox_outlined,
                    "Requests",
                    5,
                    badgeCount: reminderCount,
                    iconSize: iconSize,
                    iconPadding: iconPadding,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget withSwipeNavigation({
    required BuildContext context,
    required int currentIndex,
    required Widget child,
  }) {
    return _SwipeNavigationContainer(
      context: context,
      currentIndex: currentIndex,
      child: child,
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData active,
    IconData inactive,
    String label,
    int index, {
    int badgeCount = 0,
    required double iconSize,
    required double iconPadding,
  }) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => _handleNavigation(context, index),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _AnimatedIcon(
              activeIcon: active,
              inactiveIcon: inactive,
              isSelected: currentIndex == index,
              badgeCount: badgeCount,
              iconSize: iconSize,
              iconPadding: iconPadding,
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    _navigateToIndex(context, currentIndex, index);
  }

  static void _navigateToIndex(
    BuildContext context,
    int currentIndex,
    int index,
  ) {
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

class _SwipeNavigationContainer extends StatefulWidget {
  final BuildContext context;
  final int currentIndex;
  final Widget child;

  const _SwipeNavigationContainer({
    required this.context,
    required this.currentIndex,
    required this.child,
  });

  @override
  State<_SwipeNavigationContainer> createState() =>
      _SwipeNavigationContainerState();
}

class _SwipeNavigationContainerState extends State<_SwipeNavigationContainer> {
  double _deltaX = 0;
  bool _handled = false;

  void _handleSwipeEnd() {
    if (_handled) return;
    final dx = _deltaX;
    if (dx.abs() < 42) return;

    final targetIndex = dx > 0
        ? widget.currentIndex - 1
        : widget.currentIndex + 1;
    if (targetIndex < 0 || targetIndex > 5) return;

    _handled = true;
    BeautifulMobileNavBar._navigateToIndex(
      widget.context,
      widget.currentIndex,
      targetIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        _deltaX = 0;
        _handled = false;
      },
      onHorizontalDragUpdate: (details) {
        _deltaX += details.delta.dx;
      },
      onHorizontalDragEnd: (_) {
        _handleSwipeEnd();
        _deltaX = 0;
      },
      onHorizontalDragCancel: () {
        _deltaX = 0;
      },
      child: widget.child,
    );
  }
}

class _AnimatedIcon extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isSelected;
  final int badgeCount;
  final double iconSize;
  final double iconPadding;

  const _AnimatedIcon({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.isSelected,
    this.badgeCount = 0,
    required this.iconSize,
    required this.iconPadding,
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
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? activeIcon : inactiveIcon,
            size: iconSize,
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
