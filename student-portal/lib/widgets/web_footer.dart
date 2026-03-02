import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  // Link Data
  final List<Map<String, String>> _footerLinks = const [
    {'title': 'Official Website', 'url': 'https://cuiwah.edu.pk/'},
    {'title': 'COMSATS Main', 'url': 'https://comsats.edu.pk/'},
    {'title': 'Local Portal', 'url': 'https://portal.cuiwah.edu.pk/'},
    {'title': 'Student Portal', 'url': 'https://cuonline.cuiwah.edu.pk:8095/'},
    {
      'title': 'RMS Console',
      'url': 'http://111.68.98.91/rms/student-console/fyp-schedule',
    },
  ];

  // FYP Team Data
  final List<String> _teamMembers = const [
    "Shumaim Zafar (FA22-BCS-082)",
    "Hassan Askari (FA22-BCS-155)",
    "Sulimana Huma (FA22-BCS-073)",
  ];

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: 'Could not open link: $urlString'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF232F3E), // Dark academic blue/grey
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          // 1. Logo or Title
          const Text(
            "COMSATS University Islamabad, Wah Campus",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),

          // 2. Links Section
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 30, // Horizontal space between links
            runSpacing: 15, // Vertical space if they wrap
            children: _footerLinks.map((link) {
              return InkWell(
                onTap: () => _launchURL(context, link['url']!),
                child: Text(
                  link['title']!,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),

          // 3. FYP Team Credits Section
          Column(
            children: [
              Text(
                "Developed by FYP Team"
                    .toUpperCase(), // Fixed: Applied to string
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 8,
                children: _teamMembers.map((member) {
                  return Text(
                    member,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade700, thickness: 1),
          const SizedBox(height: 15),

          // 4. Copyright Section
          Text(
            "© ${DateTime.now().year} Student Job Fair Portal. All rights reserved.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Version 1.0.0",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
