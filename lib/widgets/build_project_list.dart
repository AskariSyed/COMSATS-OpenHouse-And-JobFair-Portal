import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/model/project.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ⚠️ Ensure this matches your actual API URL
const String _serverBaseUrl = "http://192.168.137.1:5158";

Widget buildProjectsList(
  List<Project>? projects,
  BuildContext context,
  Function(Project) onManage,
) {
  if (projects == null || projects.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "No projects added yet.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final double availableWidth = constraints.maxWidth;

      // 🔹 Responsive Columns Logic
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
        children: projects.map((project) {
          return SizedBox(
            width: columns > 1 ? cardWidth : double.infinity,
            child: ProjectCard(project: project, onManage: onManage),
          );
        }).toList(),
      );
    },
  );
}

class ProjectCard extends StatefulWidget {
  final Project project;
  final Function(Project) onManage;

  const ProjectCard({super.key, required this.project, required this.onManage});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final title = project.title;
    final typeString = project.type.toString().split('.').last;
    final desc = project.description ?? '';
    final demoUrl = project.demoUrl;
    final gitUrl = project.gitHubUrl;

    // 🔹 Get Current Student Info for "Me" logic
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final myself = studentProvider.student;

    // 🔹 Construct Member List (Me + Partners)
    List<Map<String, dynamic>> allMembers = [];
    if (myself != null) {
      allMembers.add({
        "name": "Me",
        "profilePicUrl": myself.profilePicUrl,
        "isCreator": project.currentStudentIsCreator,
        "isMe": true,
      });
    }
    for (var partner in project.partners) {
      if (myself != null && partner.name == myself.user.fullName) continue;
      allMembers.add({
        "name": partner.name,
        "profilePicUrl": partner.profilePicUrl,
        "isCreator": partner.isCreator,
        "isMe": false,
      });
    }

    // Color coding
    Color typeColor = Colors.blue;
    if (project.type == ProjectType.FinalYear) typeColor = Colors.amber;
    if (project.type == ProjectType.Freelance) typeColor = Colors.green;

    String? youtubeId;
    if (demoUrl != null) {
      youtubeId = YoutubePlayer.convertUrlToId(demoUrl);
    }
    final String? thumbnailUrl = youtubeId != null
        ? "https://img.youtube.com/vi/$youtubeId/mqdefault.jpg"
        : null;

    // Check expansion logic (Desc exists OR more than 4 members)
    final bool hasContentToExpand = desc.isNotEmpty || allMembers.length > 4;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Thumbnail (Fixed Height 140) ---
          if (thumbnailUrl != null)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade100),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.videocam_off, color: Colors.grey),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse(demoUrl!);
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {}
                      },
                    ),
                  ),
                ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 2. Title & Type (Fixed Height Logic) ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: _isExpanded ? null : 1,
                        overflow: _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeString,
                        style: TextStyle(
                          color: typeColor.withOpacity(1.0),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // --- 3. HIDDEN DESCRIPTION (Expands in Middle) ---
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _isExpanded && desc.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            desc,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 12),

                // --- 4. MEMBERS SECTION (Single Line vs Separate Lines) ---
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,

                  // 🔹 COLLAPSED: Single Row (Single Line)
                  firstChild: SizedBox(
                    height: 24,
                    child: Row(
                      children: allMembers.take(5).map((member) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _buildMemberAvatar(member, size: 22),
                        );
                      }).toList(),
                    ),
                  ),

                  // 🔹 EXPANDED: Vertical Column (Separate Lines)
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "Team:",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Using Column to force separate lines vertically
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: allMembers.map((member) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                _buildMemberAvatar(member, size: 26),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member['name'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: member['isMe']
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: member['isMe']
                                              ? Colors.black
                                              : Colors.grey.shade800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (member['isCreator'])
                                        const Text(
                                          "Team Lead",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.amber,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // --- 5. FOOTER (Actions Left/Right, Arrow Center) ---
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade50.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT: Visit & Code Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (demoUrl != null &&
                        demoUrl.isNotEmpty &&
                        youtubeId == null)
                      _buildMiniButton(
                        icon: Icons.language,
                        color: Colors.blue,
                        tooltip: "Visit Website",
                        onTap: () => launchUrl(
                          Uri.parse(demoUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    if (gitUrl != null && gitUrl.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _buildMiniButton(
                        icon: FontAwesomeIcons.github,
                        color: Colors.black87,
                        tooltip: "View Code",
                        onTap: () => launchUrl(
                          Uri.parse(gitUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ],
                ),

                // CENTER: Expand Arrow
                Expanded(
                  child: Center(
                    child: hasContentToExpand
                        ? InkWell(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),

                // RIGHT: Manage Button
                _buildMiniButton(
                  icon: project.currentStudentIsCreator
                      ? Icons.settings
                      : Icons.exit_to_app,
                  color: project.currentStudentIsCreator
                      ? Colors.grey.shade700
                      : Colors.red,
                  tooltip: project.currentStudentIsCreator ? "Manage" : "Leave",
                  onTap: () => widget.onManage(project),
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
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  // 🔹 Helper to build consistent Avatars
  Widget _buildMemberAvatar(
    Map<String, dynamic> member, {
    required double size,
  }) {
    final bool isCreator = member['isCreator'];
    final String? picUrl = member['profilePicUrl'];
    final String? fullImgUrl = (picUrl != null && picUrl.isNotEmpty)
        ? (picUrl.startsWith('http') ? picUrl : "$_serverBaseUrl$picUrl")
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCreator ? Colors.amber : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: fullImgUrl != null
            ? CachedNetworkImage(
                imageUrl: fullImgUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.person, size: 12, color: Colors.grey),
              )
            : Container(
                color: isCreator ? Colors.amber.shade100 : Colors.grey.shade200,
                alignment: Alignment.center,
                child: Text(
                  member['name'].isNotEmpty
                      ? member['name'][0].toUpperCase()
                      : "?",
                  style: TextStyle(
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.bold,
                    color: isCreator ? Colors.brown : Colors.black54,
                  ),
                ),
              ),
      ),
    );
  }
}
