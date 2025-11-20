import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/certification.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/mixins/dateFormatter.dart';
import 'package:student_job_fair_portal/mixins/launchUrl.dart';
import 'package:student_job_fair_portal/widgets/build_empty_state.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

Widget buildCertificationsList(
  List<dynamic>? certifications,
  BuildContext context,
) {
  if (certifications == null || certifications.isEmpty) {
    return buildEmptyState("No certifications added.");
  }

  // 🔹 Helper: Open Edit Dialog
  void _showEditCertificationDialog(Certification cert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Feature: Open Edit Dialog for ${cert.title}")),
    );
  }

  // 🔹 Helper: Confirm Delete
  Future<bool> _confirmAndDelete(int certificationId) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text("Remove Certification?"),
              content: const Text(
                "Are you sure you want to delete this record?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop(true);
                    // Call API
                    bool success = await Provider.of<StudentProvider>(
                      context,
                      listen: false,
                    ).deleteCertification(certificationId);

                    if (!success) {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.error(
                          message: "Failed to delete certification.",
                        ),
                      );
                    } else {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.success(
                          message: "Certification deleted successfully.",
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // 🔹 RESPONSIVE LAYOUT BUILDER (Matches Projects & Achievements)
  return LayoutBuilder(
    builder: (context, constraints) {
      final double availableWidth = constraints.maxWidth;

      // Calculate Columns based on width
      int columns = 1;
      if (availableWidth > 1350) {
        columns = 5;
      } else if (availableWidth > 1000) {
        columns = 4;
      } else if (availableWidth > 700) {
        columns = 3;
      } else if (availableWidth > 450) {
        columns = 2;
      } else {
        columns = 1;
      }

      final double spacing = 16.0;
      final double totalSpacing = (columns - 1) * spacing;
      final double cardWidth = (availableWidth - totalSpacing) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: certifications.map<Widget>((certification) {
          final cert = certification as Certification;

          Widget cardWidget = CertificationCard(
            certification: cert,
            onEdit: () => _showEditCertificationDialog(cert),
            onDelete: () => _confirmAndDelete(cert.certificationId),
          );

          // Swipe-to-delete only on mobile (1 column)
          if (columns == 1) {
            cardWidget = Dismissible(
              key: Key(cert.certificationId.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
              confirmDismiss: (direction) =>
                  _confirmAndDelete(cert.certificationId),
              child: cardWidget,
            );
          }

          return SizedBox(width: cardWidth, child: cardWidget);
        }).toList(),
      );
    },
  );
}

// 🔹 STATEFUL CARD WIDGET
class CertificationCard extends StatefulWidget {
  final Certification certification;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CertificationCard({
    super.key,
    required this.certification,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CertificationCard> createState() => _CertificationCardState();
}

class _CertificationCardState extends State<CertificationCard>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final cert = widget.certification;

    // 🔹 Dynamic Check for Issuer (Handles Nulls)
    final bool hasIssuer = cert.issuer != null && cert.issuer!.isNotEmpty;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero, // Controlled by Wrap
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Top Row: Icon & Date ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.certificate,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formatDate(cert.issueDate),
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // --- 2. Title (Full Text) ---
                Text(
                  cert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),

                // --- 3. Issuer (Subtitle - Conditional) ---
                if (hasIssuer) ...[
                  const SizedBox(height: 4),
                  Text(
                    cert.issuer!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // --- 4. Bottom Footer ---
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade50.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT: View Credential Button
                if (cert.credentialUrl != null &&
                    cert.credentialUrl!.isNotEmpty)
                  _buildMiniButton(
                    icon: Icons.open_in_new,
                    color: Colors.green,
                    tooltip: "View Credential",
                    onTap: () => launchURL(cert.credentialUrl, context),
                  )
                else
                  const SizedBox(width: 32), // Balance layout
                // CENTER: Spacer (No expand button needed for Certs)
                const Expanded(child: SizedBox()),

                // RIGHT: Edit/Delete Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniButton(
                      icon: Icons.edit,
                      color: Colors.blue,
                      onTap: widget.onEdit,
                      tooltip: "Edit",
                    ),
                    const SizedBox(width: 4),
                    _buildMiniButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: widget.onDelete,
                      tooltip: "Delete",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Helper for compact Footer Buttons
  Widget _buildMiniButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 16, color: color.withOpacity(0.8)),
          ),
        ),
      ),
    );
  }
}
