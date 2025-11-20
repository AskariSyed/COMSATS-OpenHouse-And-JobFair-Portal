import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';
import 'package:student_job_fair_portal/model/contact_link.dart'; // import your model

Widget interactiveLinkButton({
  required BuildContext context,
  required ContactLink link, // ⚠️ use ContactLink instead of Map
  required Function(ContactLink) onEdit,
  required Function(ContactLink) onDelete,
  required VoidCallback onTap,
  required Widget child,
}) {
  return Listener(
    onPointerDown: (event) {
      if (event.kind == PointerDeviceKind.mouse &&
          event.buttons == kSecondaryMouseButton) {
        showContactLinkActions(
          context,
          link: link,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      }
    },
    child: GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showContactLinkActions(
          context,
          link: link,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      child: child,
    ),
  );
}
