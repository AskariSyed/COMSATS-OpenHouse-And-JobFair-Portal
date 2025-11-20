import 'package:flutter/material.dart';

void showLinkActions(
  BuildContext context,
  dynamic link,
  Function(dynamic) onEditLink,
  Function(dynamic) onDeleteLink,
) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
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
