import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class InvitationsList extends StatelessWidget {
  const InvitationsList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProvider>(context);
    final invitations = provider.invitations;

    if (invitations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "✨ Project Invitations",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invitations.length,
          itemBuilder: (ctx, index) {
            final invite = invitations[index];
            return Card(
              elevation: 3,
              shadowColor: Colors.deepPurple.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.projectTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Type: ${invite.type}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (invite.description != null) ...[
                      const SizedBox(height: 8),
                      Text(invite.description!),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            try {
                              bool success = await provider.respondToInvitation(
                                invite.id,
                                false,
                              );
                              if (success && context.mounted) {
                                showTopSnackBar(
                                  Overlay.of(context),
                                  const CustomSnackBar.info(
                                    message: "Invitation Rejected",
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showTopSnackBar(
                                  Overlay.of(context),
                                  CustomSnackBar.error(
                                    message: e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            "Reject",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              bool success = await provider.respondToInvitation(
                                invite.id,
                                true,
                              );
                              if (success && context.mounted) {
                                showTopSnackBar(
                                  Overlay.of(context),
                                  const CustomSnackBar.success(
                                    message: "Joined Project!",
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showTopSnackBar(
                                  Overlay.of(context),
                                  CustomSnackBar.error(
                                    message: e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          icon: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            "Accept",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30), // Spacing before next section
      ],
    );
  }
}
