import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/projectMember.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';

void showProjectMembersSheet(
  BuildContext context,
  int projectId,
  String projectTitle,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) {
          return FutureBuilder<List<ProjectMember>>(
            future: Provider.of<StudentProvider>(
              context,
              listen: false,
            ).fetchProjectMembers(projectId),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No members found."));
              }

              final members = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Members: $projectTitle",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${members.length} members",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Divider(height: 30),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, index) {
                          final member = members[index];
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
                            subtitle: Text(
                              "${member.registrationNo} • ${member.role}",
                            ),
                            trailing: Container(
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
      );
    },
  );
}
