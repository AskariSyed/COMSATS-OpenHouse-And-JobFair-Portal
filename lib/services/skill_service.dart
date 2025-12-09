import 'dart:convert';
import 'package:flutter/services.dart';

class SkillCategory {
  final String name;
  final List<String> skills;

  SkillCategory({required this.name, required this.skills});
}

class SkillService {
  Future<List<SkillCategory>> loadSkills() async {
    try {
      // Load JSON from assets
      final String response = await rootBundle.loadString('assets/skills.json');
      final data = json.decode(response);

      List<SkillCategory> categories = [];

      // 1. Parse Departments
      if (data['departments'] != null) {
        for (var dept in data['departments']) {
          String deptName = dept['name'];

          // Technical Skills
          if (dept['technical_skills'] != null) {
            categories.add(
              SkillCategory(
                name: "$deptName - Technical",
                skills: List<String>.from(dept['technical_skills']),
              ),
            );
          }

          // Tools
          if (dept['tools'] != null) {
            categories.add(
              SkillCategory(
                name: "$deptName - Tools",
                skills: List<String>.from(dept['tools']),
              ),
            );
          }

          if (dept['certifications'] != null) {
            categories.add(
              SkillCategory(
                name: "$deptName - Certifications",
                skills: List<String>.from(dept['certifications']),
              ),
            );
          }
        }
      }

      // 2. Parse Soft Skills
      if (data['soft_skills'] != null) {
        for (var soft in data['soft_skills']) {
          categories.add(
            SkillCategory(
              name: "Soft Skills - ${soft['category']}",
              skills: List<String>.from(soft['skills']),
            ),
          );
        }
      }

      return categories;
    } catch (e) {
      print("Error loading skills: $e");
      return [];
    }
  }
}
