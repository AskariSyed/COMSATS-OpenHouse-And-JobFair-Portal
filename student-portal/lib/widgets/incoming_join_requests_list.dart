import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';

class IncomingJoinRequestsList extends StatelessWidget {
  const IncomingJoinRequestsList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProvider>(context);
    final requests = provider.incomingJoinRequests;

    if (requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "📥 Incoming FYP Join Requests",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (ctx, index) {
            final request = requests[index];
            final requesterName = (request['requesterName'] ?? 'Student')
                .toString();
            final requesterRegNo = (request['requesterRegistrationNo'] ?? '')
                .toString();
            final projectTitle =
                (request['projectTitle'] ?? 'Final Year Project').toString();

            return Card(
              elevation: 2,
              shadowColor: Colors.indigo.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  projectTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  "$requesterName ($requesterRegNo)",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _handleResponse(
                        ctx,
                        provider,
                        request['id'],
                        false,
                      ),
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Reject',
                    ),
                    IconButton(
                      onPressed: () => _handleResponse(
                        ctx,
                        provider,
                        request['id'],
                        true,
                      ),
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Accept',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _handleResponse(
    BuildContext context,
    StudentProvider provider,
    int requestId,
    bool accept,
  ) async {
    try {
      final success = await provider.respondToJoinRequest(requestId, accept);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? "Join request accepted!" : "Join request rejected.",
            ),
            backgroundColor: accept ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
