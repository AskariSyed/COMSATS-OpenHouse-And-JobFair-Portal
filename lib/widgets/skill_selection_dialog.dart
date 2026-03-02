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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Skills"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
                  decoration: InputDecoration(
                    labelText: "Search Skills (e.g. React, SQL)",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: _onSearchChanged,
                ),

                const SizedBox(height: 12),

                // 🔹 DEPARTMENT DROPDOWN (Only show if not searching)
                if (_searchQuery.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDepartment,
                        isExpanded: true,
                        icon: const Icon(Icons.filter_list),
                        items: _allDepartments.map((String dept) {
                          return DropdownMenuItem<String>(
                            value: dept,
                            child: Text(
                              dept,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
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
                ? const Center(child: Text("No skills found."))
                : isWeb
                ? _buildWebGrid(displayedSkills) // Grid for Web
                : _buildMobileList(displayedSkills), // List for Mobile
          ),

          // 🔹 Footer showing count
          if (_selectedSkills.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Text(
                    "${_selectedSkills.length} skills selected",
                    style: TextStyle(
                      color: Colors.blue.shade900,
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

  Widget _buildWebGrid(List<String> skills) {
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
                    : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
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
                            ? Colors.blue.shade900
                            : Colors.black87,
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

  Widget _buildMobileList(List<String> skills) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: skills.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final skill = skills[index];
        final isSelected = _selectedSkills.contains(skill);
        return CheckboxListTile(
          title: Text(skill),
          value: isSelected,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (val) => _toggleSkill(skill),
        );
      },
    );
  }
}
