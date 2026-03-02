import 'package:flutter/material.dart';

void handleLinkOptions({
  required BuildContext context,
  required dynamic link,
  required Function(dynamic link) onEditLink,
  required Function(dynamic link) onDeleteLink,
}) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text("Edit Link"),
            onTap: () {
              Navigator.pop(context);
              onEditLink(link);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Remove Link"),
            onTap: () {
              Navigator.pop(context);
              onDeleteLink(link);
            },
          ),
        ],
      ),
    ),
  );
}
