import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:student_job_fair_portal/mixins/launchUrl.dart';
import 'package:student_job_fair_portal/widgets/build_empty_state.dart';

Widget buildFypCard(BuildContext context, dynamic student) {
  if (student.fypTitle == null || student.fypTitle!.isEmpty) {
    return buildEmptyState("FYP details not added.");
  }
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => launchURL(student.fypDemoUrl, context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  'https://images.unsplash.com/photo-1551288049-bebda4e38f71?ixlib=rb-4.0.3',
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) =>
                      Container(color: Colors.grey.shade300),
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      student.fypTitle ?? "Project Title",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (student.fypGithubUrl != null &&
                      student.fypGithubUrl!.isNotEmpty)
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.github, size: 22),
                      onPressed: () => launchURL(student.fypGithubUrl, context),
                      tooltip: 'View Source Code',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                student.fypDescription ?? "No description provided.",
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
