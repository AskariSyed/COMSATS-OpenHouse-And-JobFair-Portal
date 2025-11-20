import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';

class AnimatedNavBar extends StatelessWidget {
  final bool isVisible;
  final String title;
  final String? photoUrl;
  final VoidCallback onMenuTap;

  const AnimatedNavBar({
    super.key,
    required this.isVisible,
    required this.title,
    this.photoUrl,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // Move it up off-screen (-100) when not visible
      transform: Matrix4.translationValues(0, isVisible ? 0 : -100, 0),
      height: 90, // Height including SafeArea
      child: Container(
        margin: const EdgeInsets.only(top: 0, left: 0, right: 0),
        child: ClipRRect(
          // No border radius at top, rounded at bottom for style
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          child: BackdropFilter(
            // THE GLASS EFFECT
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                40,
                20,
                10,
              ), // Pad for Status Bar
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7), // Semi-transparent white
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu Button
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.indigo),
                    onPressed: onMenuTap,
                  ),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Profile Pic or Icon
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.indigo.shade50,
                      image: photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: photoUrl == null
                        ? const Icon(Icons.person, color: Colors.indigo)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
