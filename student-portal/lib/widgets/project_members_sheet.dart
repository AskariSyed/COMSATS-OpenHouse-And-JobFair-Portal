import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/projectMember.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';

void showProjectMembersSheet(
  BuildContext context,
  int projectId,
  String projectTitle,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final width = MediaQuery.of(context).size.width;
      final studentProvider = Provider.of<StudentProvider>(
        context,
        listen: false,
      );
      final currentStudentId = studentProvider.student?.studentId;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: width < 700 ? 16 : 24,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: width < 700 ? 560 : 620,
          ),
          child: FutureBuilder<List<ProjectMember>>(
            future: studentProvider.fetchProjectMembers(projectId),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text("No members found.")),
                );
              }

              final members = snapshot.data!;
              final isTeamLead = members.any(
                (m) => m.isCreator && m.studentId == currentStudentId,
              );

              return StatefulBuilder(
                builder: (ctx, setState) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Members: $projectTitle",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: Icon(
                                Icons.close,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${members.length} members",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Divider(height: 24),
                        Expanded(
                          child: ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final member = members[index];
                              final isCurrentUser =
                                  member.studentId == currentStudentId;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: member.isCreator
                                      ? Colors.amber.shade100
                                      : Colors.blue.shade50,
                                  child: Text(
                                    member.fullName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: member.isCreator
                                          ? Colors.amber.shade900
                                          : Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  member.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${member.registrationNo} • ${member.role}",
                                    ),
                                    if (member.isCreator)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Team Lead",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: member.status == 1
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        member.statusString,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: member.status == 1
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isTeamLead &&
                                        !isCurrentUser &&
                                        !member.isCreator)
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: ctx,
                                            builder: (confirmCtx) => AlertDialog(
                                              title: const Text(
                                                "Remove Member",
                                              ),
                                              content: Text(
                                                "Are you sure you want to remove ${member.fullName} from this project?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    confirmCtx,
                                                  ).pop(),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.of(
                                                      confirmCtx,
                                                    ).pop();

                                                    final success =
                                                        await studentProvider
                                                            .removeMember(
                                                              projectId,
                                                              member.studentId,
                                                            );

                                                    if (success) {
                                                      if (ctx.mounted) {
                                                        setState(() {
                                                          members.removeWhere(
                                                            (m) =>
                                                                m.studentId ==
                                                                member
                                                                    .studentId,
                                                          );
                                                        });
                                                      }
                                                      ScaffoldMessenger.of(
                                                        ctx,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            "${member.fullName} removed from project",
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                        ctx,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Failed to remove member",
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: const Text(
                                                    "Remove",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        splashRadius: 20,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}
