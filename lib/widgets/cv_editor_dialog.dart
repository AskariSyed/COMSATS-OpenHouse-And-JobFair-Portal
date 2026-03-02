import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/model/project.dart';
import 'package:student_job_fair_portal/model/experience.dart';
import 'package:student_job_fair_portal/model/education.dart';
import 'package:student_job_fair_portal/model/certification.dart';
import 'package:student_job_fair_portal/model/achievement.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/mixins/contactPlaytformToString.dart';

class CVEditorDialog extends StatefulWidget {
  const CVEditorDialog({super.key});

  @override
  State<CVEditorDialog> createState() => _CVEditorDialogState();
}

class _CVEditorDialogState extends State<CVEditorDialog> {
  bool loading = false;
  bool _initialized = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillController = TextEditingController();
  String? cvEmail; // CV-specific email that doesn't update backend

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _savePersonal(StudentProvider provider) async {
    setState(() => loading = true);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isNotEmpty && name != provider.student?.user.fullName) {
      await provider.updateFullName(name);
    }
    if (phone.isNotEmpty && phone != provider.student?.user.phone) {
      await provider.updatePhoneNumber(phone);
    }
    await provider.fetchProfile();
    setState(() => loading = false);
  }

  Future<void> _addSkill(StudentProvider provider) async {
    final text = _skillController.text.trim();
    if (text.isEmpty) return;
    final newList = List<String>.from(provider.student?.skills ?? [])
      ..add(text);
    setState(() => loading = true);
    final ok = await provider.putSkills(newList);
    if (ok) _skillController.clear();
    await provider.fetchProfile();
    setState(() => loading = false);
  }

  Future<void> _removeSkill(StudentProvider provider, String skill) async {
    setState(() => loading = true);
    final ok = await provider.removeSkill(skill);
    if (!ok) {
      final updated = List<String>.from(provider.student?.skills ?? [])
        ..remove(skill);
      await provider.putSkills(updated);
    }
    await provider.fetchProfile();
    setState(() => loading = false);
  }

  Widget _sectionHeaderWithAction(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add),
          label: Text(actionLabel),
        ),
      ],
    );
  }

  Future<void> _showProjectEditor(
    StudentProvider provider, {
    Project? project,
  }) async {
    final titleCtrl = TextEditingController(text: project?.title ?? '');
    final descCtrl = TextEditingController(text: project?.description ?? '');
    final skillsCtrl = TextEditingController(text: project?.skills ?? '');
    final partnersCtrl = TextEditingController(
      text: project?.partners.map((p) => p.name).join(', ') ?? '',
    );
    final demoCtrl = TextEditingController(text: project?.demoUrl ?? '');
    final gitCtrl = TextEditingController(text: project?.gitHubUrl ?? '');
    int? typeIndex = project?.type.index ?? 0;

    final formKey = GlobalKey<FormState>();
    bool isValidUrl(String? value) {
      if (value == null || value.trim().isEmpty) return true;
      final uri = Uri.tryParse(value);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(project == null ? 'Add Project' : 'Edit Project'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: typeIndex,
                  items: ProjectType.values
                      .asMap()
                      .entries
                      .map(
                        (e) => DropdownMenuItem<int>(
                          value: e.key,
                          child: Text(e.value.toString().split('.').last),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => typeIndex = v ?? 0,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Skills (comma separated)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: partnersCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Partners (comma separated)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: demoCtrl,
                  decoration: const InputDecoration(labelText: 'Demo URL'),
                  validator: (v) => isValidUrl(v) ? null : 'Enter a valid URL',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: gitCtrl,
                  decoration: const InputDecoration(labelText: 'GitHub URL'),
                  validator: (v) => isValidUrl(v) ? null : 'Enter a valid URL',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx);
              setState(() => loading = true);
              final data = {
                'title': titleCtrl.text.trim(),
                'type': typeIndex,
                'description': descCtrl.text.trim(),
                'skills': skillsCtrl.text.trim(),
                'partners': partnersCtrl.text.trim(),
                'demoUrl': demoCtrl.text.trim(),
                'gitHubUrl': gitCtrl.text.trim(),
              };
              if (project == null) {
                await provider.createProject(data);
              } else {
                await provider.updateProject(project.projectId, data);
              }
              await provider.fetchProfile();
              setState(() => loading = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExperienceEditor(
    StudentProvider provider, {
    Experience? experience,
  }) async {
    final company = TextEditingController(text: experience?.companyName ?? '');
    final role = TextEditingController(text: experience?.role ?? '');
    final desc = TextEditingController(text: experience?.description ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(experience == null ? 'Add Experience' : 'Edit Experience'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: company,
                  decoration: const InputDecoration(labelText: 'Company'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter company' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: role,
                  decoration: const InputDecoration(
                    labelText: 'Role / Position',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter role' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: desc,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    counterText: "",
                    helperText: "Max 500 characters",
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx);
              setState(() => loading = true);
              final data = {
                'companyName': company.text.trim(),
                'role': role.text.trim(),
                'description': desc.text.trim(),
              };
              if (experience == null) {
                await provider.addExperience(data);
              } else {
                await provider.updateExperience(experience.experienceId, data);
              }
              await provider.fetchExperiences();
              await provider.fetchProfile();
              setState(() => loading = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEducationEditor(
    StudentProvider provider, {
    Education? education,
  }) async {
    final inst = TextEditingController(text: education?.institutionName ?? '');
    final degree = TextEditingController(text: education?.degree ?? '');
    final field = TextEditingController(text: education?.fieldOfStudy ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(education == null ? 'Add Education' : 'Edit Education'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: inst,
                  decoration: const InputDecoration(labelText: 'Institution'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter institution'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: degree,
                  decoration: const InputDecoration(labelText: 'Degree'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter degree' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: field,
                  decoration: const InputDecoration(
                    labelText: 'Field of study',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx);
              setState(() => loading = true);
              final data = {
                'institutionName': inst.text.trim(),
                'degree': degree.text.trim(),
                'fieldOfStudy': field.text.trim(),
              };
              if (education == null) {
                await provider.addEducation(data);
              } else {
                await provider.updateEducation(education.educationId, data);
              }
              await provider.fetchProfile();
              setState(() => loading = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCertificationEditor(
    StudentProvider provider, {
    Certification? certification,
  }) async {
    final title = TextEditingController(text: certification?.title ?? '');
    final issuer = TextEditingController(text: certification?.issuer ?? '');
    final url = TextEditingController(text: certification?.credentialUrl ?? '');
    final formKey = GlobalKey<FormState>();
    bool isValidUrl(String? value) {
      if (value == null || value.trim().isEmpty) return true;
      final uri = Uri.tryParse(value);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          certification == null ? 'Add Certification' : 'Edit Certification',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: issuer,
                  decoration: const InputDecoration(labelText: 'Issuer'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: url,
                  decoration: const InputDecoration(
                    labelText: 'Credential URL',
                  ),
                  validator: (v) => isValidUrl(v) ? null : 'Enter a valid URL',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx);
              setState(() => loading = true);
              final data = {
                'title': title.text.trim(),
                'issuer': issuer.text.trim(),
                'credentialUrl': url.text.trim(),
              };
              if (certification == null) {
                await provider.addCertification(data);
              } else {
                await provider.updateCertification(
                  certification.certificationId,
                  data,
                );
              }
              await provider.fetchProfile();
              setState(() => loading = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAchievementEditor(
    StudentProvider provider, {
    Achievement? achievement,
  }) async {
    final title = TextEditingController(text: achievement?.title ?? '');
    final desc = TextEditingController(text: achievement?.description ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          achievement == null ? 'Add Achievement' : 'Edit Achievement',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx);
              setState(() => loading = true);
              final data = {
                'title': title.text.trim(),
                'description': desc.text.trim(),
              };
              if (achievement == null) {
                await provider.addAchievement(data);
              } else {
                await provider.updateAchievement(
                  achievement.achievementId,
                  data,
                );
              }
              await provider.fetchProfile();
              setState(() => loading = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showContactLinkEditor(
    StudentProvider provider, {
    ContactLink? contactLink,
  }) async {
    final platforms = const [
      'LinkedIn',
      'GitHub',
      'Portfolio',
      'Twitter',
      'Facebook',
      'Instagram',
      'Other',
    ];
    String selectedPlatform = contactLink != null
        ? contactPlatformToString(contactLink.platform)
        : platforms.first;
    final urlCtrl = TextEditingController(text: contactLink?.url ?? '');
    final formKey = GlobalKey<FormState>();
    bool isValidUrl(String? value) {
      if (value == null || value.trim().isEmpty) return false;
      final uri = Uri.tryParse(value);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            contactLink == null ? 'Add Contact Link' : 'Edit Contact Link',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlatform,
                    items: platforms
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p,
                            child: Text(p),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setStateDialog(() {
                        selectedPlatform = v ?? platforms.first;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Platform'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(labelText: 'URL'),
                    validator: (v) =>
                        isValidUrl(v) ? null : 'Enter a valid http(s) URL',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(ctx);
                setState(() => loading = true);
                final data = {
                  'platform': selectedPlatform,
                  'url': urlCtrl.text.trim(),
                };
                if (contactLink == null) {
                  await provider.addContactLink(data);
                } else {
                  await provider.updateContactLink(contactLink.linkId, data);
                }
                await provider.fetchProfile();
                setState(() => loading = false);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProvider>(context);
    final student = provider.student;

    if (student == null) {
      return AlertDialog(
        title: const Text('CV Editor'),
        content: const Text('You must be logged in to edit your CV.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
    if (!_initialized) {
      _nameController.text = student.user.fullName ?? '';
      _emailController.text = student.user.email;
      _phoneController.text = student.user.phone ?? '';
      cvEmail = student.user.email;
      _initialized = true;
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit CV Contents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Left column
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email (CV Display Only)',
                                helperText:
                                    'This email will only appear on your CV',
                                helperMaxLines: 2,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) {
                                setState(() {
                                  cvEmail = value.trim();
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                              ),
                            ),
                            const SizedBox(height: 12),

                            const Text(
                              'Skills',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Wrap(
                                key: ValueKey<int>(student.skills.length),
                                spacing: 6,
                                runSpacing: 6,
                                children: student.skills
                                    .map(
                                      (s) => Chip(
                                        label: Text(s),
                                        onDeleted: () =>
                                            _removeSkill(provider, s),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _skillController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add skill',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _addSkill(provider),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            _sectionHeaderWithAction(
                              context,
                              title: 'Experiences',
                              actionLabel: 'Add',
                              onAction: () => _showExperienceEditor(provider),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                children:
                                    (student.experiences.toList()..sort(
                                          (a, b) => b.startDate.compareTo(
                                            a.startDate,
                                          ),
                                        ))
                                        .map(
                                          (e) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                '${e.role} @ ${e.companyName}',
                                              ),
                                              subtitle: Text(
                                                e.description ?? '',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    onPressed: () =>
                                                        _showExperienceEditor(
                                                          provider,
                                                          experience: e,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                    ),
                                                    onPressed: () async {
                                                      final ok = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text(
                                                            'Remove Experience',
                                                          ),
                                                          content: const Text(
                                                            'Remove this experience entry?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Remove',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (ok == true &&
                                                          mounted) {
                                                        setState(
                                                          () => loading = true,
                                                        );
                                                        await provider
                                                            .deleteExperience(
                                                              e.experienceId,
                                                            );
                                                        await provider
                                                            .fetchExperiences();
                                                        await provider
                                                            .fetchProfile();
                                                        setState(
                                                          () => loading = false,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            _sectionHeaderWithAction(
                              context,
                              title: 'Education',
                              actionLabel: 'Add',
                              onAction: () => _showEducationEditor(provider),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                children:
                                    (student.educations.toList()..sort(
                                          (a, b) =>
                                              (b.startDate ?? DateTime(1900))
                                                  .compareTo(
                                                    a.startDate ??
                                                        DateTime(1900),
                                                  ),
                                        ))
                                        .map(
                                          (ed) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: ListTile(
                                              title: Text(ed.institutionName),
                                              subtitle: Text(
                                                '${ed.degree} • ${ed.fieldOfStudy}',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    onPressed: () =>
                                                        _showEducationEditor(
                                                          provider,
                                                          education: ed,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                    ),
                                                    onPressed: () async {
                                                      final ok = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text(
                                                            'Remove Education',
                                                          ),
                                                          content: const Text(
                                                            'Remove this education entry?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Remove',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (ok == true &&
                                                          mounted) {
                                                        setState(
                                                          () => loading = true,
                                                        );
                                                        await provider
                                                            .deleteEducation(
                                                              ed.educationId,
                                                            );
                                                        await provider
                                                            .fetchProfile();
                                                        setState(
                                                          () => loading = false,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            _sectionHeaderWithAction(
                              context,
                              title: 'Certifications',
                              actionLabel: 'Add',
                              onAction: () =>
                                  _showCertificationEditor(provider),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                children:
                                    (student.certifications.toList()..sort(
                                          (a, b) =>
                                              (b.issueDate ?? DateTime(1900))
                                                  .compareTo(
                                                    a.issueDate ??
                                                        DateTime(1900),
                                                  ),
                                        ))
                                        .map(
                                          (c) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: ListTile(
                                              title: Text(c.title),
                                              subtitle: Text(c.issuer ?? ''),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    onPressed: () =>
                                                        _showCertificationEditor(
                                                          provider,
                                                          certification: c,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                    ),
                                                    onPressed: () async {
                                                      final ok = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text(
                                                            'Remove Certification',
                                                          ),
                                                          content: const Text(
                                                            'Remove this certification?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Remove',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (ok == true &&
                                                          mounted) {
                                                        setState(
                                                          () => loading = true,
                                                        );
                                                        await provider
                                                            .deleteCertification(
                                                              c.certificationId,
                                                            );
                                                        await provider
                                                            .fetchProfile();
                                                        setState(
                                                          () => loading = false,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            _sectionHeaderWithAction(
                              context,
                              title: 'Achievements',
                              actionLabel: 'Add',
                              onAction: () => _showAchievementEditor(provider),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                children:
                                    (student.achievements.toList()..sort(
                                          (a, b) => b.dateAchieved.compareTo(
                                            a.dateAchieved,
                                          ),
                                        ))
                                        .map(
                                          (a) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: ListTile(
                                              title: Text(a.title),
                                              subtitle: Text(
                                                a.description ?? '',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    onPressed: () =>
                                                        _showAchievementEditor(
                                                          provider,
                                                          achievement: a,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                    ),
                                                    onPressed: () async {
                                                      final ok = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text(
                                                            'Remove Achievement',
                                                          ),
                                                          content: const Text(
                                                            'Remove this achievement?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Remove',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (ok == true &&
                                                          mounted) {
                                                        setState(
                                                          () => loading = true,
                                                        );
                                                        await provider
                                                            .deleteAchievement(
                                                              a.achievementId,
                                                            );
                                                        await provider
                                                            .fetchProfile();
                                                        setState(
                                                          () => loading = false,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            _sectionHeaderWithAction(
                              context,
                              title: 'Contact Links',
                              actionLabel: 'Add',
                              onAction: () => _showContactLinkEditor(provider),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                children: student.contactLinks
                                    .map(
                                      (link) => Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            contactPlatformToString(
                                              link.platform,
                                            ),
                                          ),
                                          subtitle: Text(link.url),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () =>
                                                    _showContactLinkEditor(
                                                      provider,
                                                      contactLink: link,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () async {
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text(
                                                        'Remove Link',
                                                      ),
                                                      content: const Text(
                                                        'Remove this contact link?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                ctx,
                                                                false,
                                                              ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                ctx,
                                                                true,
                                                              ),
                                                          child: const Text(
                                                            'Remove',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok == true && mounted) {
                                                    setState(
                                                      () => loading = true,
                                                    );
                                                    await provider
                                                        .deleteContactLink(
                                                          link.linkId,
                                                        );
                                                    await provider
                                                        .fetchProfile();
                                                    setState(
                                                      () => loading = false,
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              'Projects',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showProjectEditor(provider),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Project'),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: student.projects
                                  .map(
                                    (p) => ListTile(
                                      title: Text(p.title),
                                      subtitle: Text(p.description ?? ''),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showProjectEditor(
                                              provider,
                                              project: p,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'Remove Project',
                                                  ),
                                                  content: const Text(
                                                    'Do you want to remove this project from your profile?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            ctx,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            ctx,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Remove',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true && mounted) {
                                                setState(() => loading = true);
                                                await provider.leaveProject(
                                                  p.projectId,
                                                );
                                                await provider.fetchProfile();
                                                setState(() => loading = false);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Right column: preview + actions
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.user.fullName ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(student.user.email),
                                    if (student.user.phone != null)
                                      Text(student.user.phone!),
                                    const Divider(),
                                    const Text(
                                      'Skills',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      children: student.skills
                                          .map((s) => Chip(label: Text(s)))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Projects',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: student.projects
                                          .map(
                                            (p) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p.title,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (p.description != null)
                                                    Text(p.description!),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, cvEmail),
                                  child: const Text('Close'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          await _savePersonal(provider);
                                          if (mounted) {
                                            Navigator.pop(context, cvEmail);
                                          }
                                        },
                                  child: loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Save & Close'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
