import 'dart:ui';

import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:student_job_fair_portal/helper/showLinkActions.dart';

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

  @override
  Widget build(BuildContext context) {
    final content = _contentToCopy;

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
            Listener(
              onPointerDown: (event) {
                // Web/Desktop Right-Click
                if (event.kind == PointerDeviceKind.mouse &&
                    event.buttons == kSecondaryMouseButton) {
                  showLinkActions(
                    widget.context,
                    widget.link,
                    widget.onEditLink,
                    widget.onDeleteLink,
                  );
                }
              },
              child: GestureDetector(
                onTap: widget.onTap,
                onLongPress: () {
                  // Mobile Long Press
                  showLinkActions(
                    widget.context,
                    widget.link,
                    widget.onEditLink,
                    widget.onDeleteLink,
                  );
                },
                child: widget.child,
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
