import 'package:flutter/material.dart';
import 'package:student_job_fair_portal/services/skill_service.dart';

class SkillSelectionDialog extends StatefulWidget {
  final List<String> previouslySelectedSkills;

  const SkillSelectionDialog({
    super.key,
    required this.previouslySelectedSkills,
  });

  @override
  State<SkillSelectionDialog> createState() => _SkillSelectionDialogState();
}

class _SkillSelectionDialogState extends State<SkillSelectionDialog> {
  final SkillService _skillService = SkillService();

  // Data
  List<SkillCategory> _allCategories = [];
  List<String> _allDepartments = ['All Departments']; // For the dropdown

  // State
  List<String> _selectedSkills = [];
  String _searchQuery = "";
  String _selectedDepartment = "All Departments";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedSkills = List.from(widget.previouslySelectedSkills);
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await _skillService.loadSkills();

    // Extract unique department names for the dropdown
    final Set<String> deptNames = {};
    for (var cat in categories) {
      // Assuming format "Department Name - Section" (e.g. "Computer Science - Technical")
      // We split by ' - ' and take the first part.
      if (cat.name.contains(' - ')) {
        deptNames.add(cat.name.split(' - ').first);
      } else {
        deptNames.add(cat.name);
      }
    }

    setState(() {
      _allCategories = categories;
      _allDepartments = ['All Departments', ...deptNames.toList()..sort()];
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  // 🔹 CORE LOGIC: Filter the skills based on Dropdown AND Search
  List<String> _getFilteredSkills() {
    // 1. If Searching, ignore dropdown and search EVERYTHING
    if (_searchQuery.isNotEmpty) {
      final allSkills = _allCategories.expand((c) => c.skills).toSet().toList();
      return allSkills
          .where((s) => s.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // 2. If Dropdown is selected, show only that department's skills
    if (_selectedDepartment != "All Departments") {
      return _allCategories
          .where((c) => c.name.startsWith(_selectedDepartment))
          .expand((c) => c.skills)
          .toList();
    }

    // 3. Otherwise, show ALL skills (flattened)
    return _allCategories.expand((c) => c.skills).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 800;
    final displayedSkills = _getFilteredSkills();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF181A20) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final searchFillColor = isDark ? const Color(0xFF23242A) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final footerBgColor = isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50;
    final footerTextColor = isDark ? Colors.blue.shade200 : Colors.blue.shade900;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: isWeb
            ? const Text("Select Skills")
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/LogoWithoutBg.png',
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  const Text("Select Skills"),
                ],
              ),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedSkills),
            child: const Text(
              "Done",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 🔹 SEARCH BAR
                TextField(
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: "Search Skills (e.g. React, SQL)",
                    labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    filled: true,
                    fillColor: searchFillColor,
                  ),
                  onChanged: _onSearchChanged,
                ),

                const SizedBox(height: 12),

                // 🔹 DEPARTMENT DROPDOWN (Only show if not searching)
                if (_searchQuery.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                      color: searchFillColor,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDepartment,
                        dropdownColor: searchFillColor,
                        isExpanded: true,
                        icon: Icon(Icons.filter_list, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        items: _allDepartments.map((String dept) {
                          return DropdownMenuItem<String>(
                            value: dept,
                            child: Text(
                              dept,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDepartment = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 🔹 SKILLS LIST / GRID
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedSkills.isEmpty
                ? Center(child: Text("No skills found.", style: TextStyle(color: textColor)))
                : isWeb
                ? _buildWebGrid(displayedSkills, isDark) // Grid for Web
                : _buildMobileList(displayedSkills, isDark), // List for Mobile
          ),

          // 🔹 Footer showing count
          if (_selectedSkills.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: footerBgColor,
              child: Row(
                children: [
                  Text(
                    "${_selectedSkills.length} skills selected",
                    style: TextStyle(
                      color: footerTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.check_circle, color: Colors.blue),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebGrid(List<String> skills, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: skills.map((skill) {
          final isSelected = _selectedSkills.contains(skill);
          return InkWell(
            onTap: () => _toggleSkill(skill),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 220, // Fixed width card
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.1)
                    : (isDark ? const Color(0xFF23242A) : Colors.white),
                border: Border.all(
                  color: isSelected ? Colors.blue : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? (isDark ? Colors.blue.shade200 : Colors.blue.shade900)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<String> skills, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: skills.length,
      separatorBuilder: (ctx, i) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      itemBuilder: (context, index) {
        final skill = skills[index];
        final isSelected = _selectedSkills.contains(skill);
        return CheckboxListTile(
          title: Text(skill, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          value: isSelected,
          activeColor: Theme.of(context).primaryColor,
          checkColor: Colors.white,
          side: BorderSide(color: isDark ? Colors.grey.shade400 : Colors.black54),
          onChanged: (val) => _toggleSkill(skill),
        );
      },
    );
  }
}
