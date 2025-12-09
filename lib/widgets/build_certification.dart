import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/certification.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/mixins/dateFormatter.dart';
import 'package:student_job_fair_portal/mixins/launchUrl.dart';
import 'package:student_job_fair_portal/mixins/date_picker.dart';
import 'package:student_job_fair_portal/widgets/build_empty_state.dart';
import 'package:student_job_fair_portal/widgets/show_gerenicpopup.dart';
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
    final titleCtrl = TextEditingController(text: cert.title);
    final issuerCtrl = TextEditingController(text: cert.issuer);
    final dateCtrl = TextEditingController(
      text: cert.issueDate?.toIso8601String().split('T').first ?? '',
    );
    final urlCtrl = TextEditingController(text: cert.credentialUrl ?? '');

    showGenericDialog(
      context: context,
      title: "Edit Certification",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: "Title"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: issuerCtrl,
            decoration: const InputDecoration(labelText: "Issuer"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: dateCtrl,
            readOnly: true,
            onTap: () => selectDate(context, dateCtrl),
            decoration: const InputDecoration(
              labelText: "Issue Date",
              hintText: "YYYY-MM-DD",
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(
              labelText: "Credential URL (Optional)",
            ),
          ),
        ],
      ),
      onSave: () async {
        final Map<String, dynamic> updateData = {
          "title": titleCtrl.text,
          "issuer": issuerCtrl.text,
          "issueDate": "${dateCtrl.text}T00:00:00Z",
        };
        if (urlCtrl.text.isNotEmpty) {
          updateData["credentialUrl"] = urlCtrl.text;
        }
        await Provider.of<StudentProvider>(
          context,
          listen: false,
        ).updateCertification(cert.certificationId, updateData);
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🔹 Dynamic Check for Issuer (Handles Nulls)
    final bool hasIssuer = cert.issuer != null && cert.issuer!.isNotEmpty;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero, // Controlled by Wrap
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Top Row: Icon & Date ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green.shade900.withOpacity(0.3)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.certificate,
                        color: isDark ? Colors.green.shade400 : Colors.green,
                        size: isMobile ? 14 : 16,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formatDate(cert.issueDate),
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                          fontSize: isMobile ? 9 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 8 : 12),

                // --- 2. Title (Full Text) ---
                Text(
                  cert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 15,
                    height: 1.2,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),

                // --- 3. Issuer (Subtitle - Conditional) ---
                if (hasIssuer) ...[
                  SizedBox(height: isMobile ? 3 : 4),
                  Text(
                    cert.issuer!,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade100,
          ),

          // --- 4. Bottom Footer ---
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.shade50.withOpacity(0.3),
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
