import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/helper/showLinkActions.dart';

Widget interactiveSocialButton({
  required BuildContext context,
  required dynamic link,
  required Function(dynamic) onEditLink,
  required Function(dynamic) onDeleteLink,
  required VoidCallback onTap,
  required Widget child,
}) {
  return Listener(
    onPointerDown: (event) {
      // Web/Desktop Right-Click
      if (event.kind == PointerDeviceKind.mouse &&
          event.buttons == kSecondaryMouseButton) {
        showLinkActions(context, link, onEditLink, onDeleteLink);
      }
    },
    child: GestureDetector(
      onTap: onTap,
      onLongPress: () {
        // Mobile Long Press
        showLinkActions(context, link, onEditLink, onDeleteLink);
      },
      child: child,
    ),
  );
}
