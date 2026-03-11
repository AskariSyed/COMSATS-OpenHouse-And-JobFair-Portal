import 'dart:ui';

import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_popup/flutter_popup.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

// 1. Convert to a Widget to handle Hover State easily
class _InteractiveButtonWrapper extends StatefulWidget {
  final BuildContext context;
  final dynamic link;
  final Function(dynamic) onEditLink;
  final Function(dynamic) onDeleteLink;
  final VoidCallback onTap;
  final Widget child;

  const _InteractiveButtonWrapper({
    required this.context,
    required this.link,
    required this.onEditLink,
    required this.onDeleteLink,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveButtonWrapper> createState() =>
      _InteractiveButtonWrapperState();
}

class _InteractiveButtonWrapperState extends State<_InteractiveButtonWrapper> {
  bool _isHovered = false;
  final GlobalKey<CustomPopupState> _popupKey = GlobalKey<CustomPopupState>();

  // Helper to safely extract URL or Email from Model, Map, or String
  String get _contentToCopy {
    // 1. If it's a simple String (e.g. passed raw email)
    if (widget.link is String) {
      return widget.link as String;
    }

    // 2. Try access as Model property (.url)
    try {
      final url = (widget.link as dynamic).url;
      if (url != null && url.toString().isNotEmpty) return url;
    } catch (_) {}

    // 3. Try access as Model property (.email)
    try {
      final email = (widget.link as dynamic).email;
      if (email != null && email.toString().isNotEmpty) return email;
    } catch (_) {}

    // 4. Try access as Map key ['url']
    try {
      if (widget.link is Map && widget.link.containsKey('url')) {
        return widget.link['url'] ?? '';
      }
    } catch (_) {}

    // 5. Try access as Map key ['email']
    try {
      if (widget.link is Map && widget.link.containsKey('email')) {
        return widget.link['email'] ?? '';
      }
    } catch (_) {}

    return '';
  }

  void _copyToClipboard() {
    final content = _contentToCopy;
    if (content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: content));
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(message: "Copied: $content"),
      );
    }
  }

  void _showActionsPopup() {
    _popupKey.currentState?.show();
  }

  Widget _buildPopupMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark
        ? const Color(0xFF3A3A4A)
        : const Color(0xFFE5E7EB);
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              widget.onEditLink(widget.link);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Edit Link',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: dividerColor),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              widget.onDeleteLink(widget.link);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                  const SizedBox(width: 10),
                  const Text(
                    'Remove Link',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _contentToCopy;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: content, // FEATURE 1: Tooltip showing URL or Email
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The Original Social Button
            CustomPopup(
              key: _popupKey,
              showArrow: true,
              barrierColor: Colors.black.withValues(alpha: 0.08),
              contentPadding: EdgeInsets.zero,
              contentDecoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D3F) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              content: _buildPopupMenu(),
              child: GestureDetector(
                onTap: widget.onTap,
                onLongPress: _showActionsPopup,
                onSecondaryTapDown: (_) => _showActionsPopup(),
                onSecondaryTapUp: (_) => _showActionsPopup(),
                child: Listener(
                  onPointerDown: (event) {
                    if (event.kind == PointerDeviceKind.mouse &&
                        event.buttons == kSecondaryMouseButton) {
                      _showActionsPopup();
                    }
                  },
                  child: widget.child,
                ),
              ),
            ),

            // FEATURE 2: Copy Button (Web Only - Shows on Hover)
            if (kIsWeb && _isHovered && content.isNotEmpty)
              Positioned(
                top: -8,
                right: -8,
                child: Material(
                  color: Colors.white,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _copyToClipboard,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.copy, size: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 2. The exposed function now returns the wrapper
Widget interactiveSocialButton({
  required BuildContext context,
  required dynamic link,
  required Function(dynamic) onEditLink,
  required Function(dynamic) onDeleteLink,
  required VoidCallback onTap,
  required Widget child,
}) {
  return _InteractiveButtonWrapper(
    context: context,
    link: link,
    onEditLink: onEditLink,
    onDeleteLink: onDeleteLink,
    onTap: onTap,
    child: child,
  );
}
