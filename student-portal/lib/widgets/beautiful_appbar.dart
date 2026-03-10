import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/theme_provider.dart';

class BeautifulAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool hideLogout;
  final VoidCallback? onSettingsPressed;

  const BeautifulAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.hideLogout = false,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 0.5,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      centerTitle: true,
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: theme.appBarTheme.elevation,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      bottom: bottom,
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
