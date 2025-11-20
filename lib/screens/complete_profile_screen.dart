import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/screens/profile.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final String _serverBaseUrl = "http://192.168.137.1:5158";

  // Controllers for the form fields
  final _phoneController = TextEditingController();
  final _skillsController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _githubController = TextEditingController();
  final _fypTitleController = TextEditingController();
  final _fypDescController = TextEditingController();
  final _fypDemoUrlController = TextEditingController();
  final _fypGithubUrlController = TextEditingController();

  // --- Image State ---
  XFile? _pickedImage; // Store the NEW file from image_picker
  Uint8List? _imageBytes; // Store the bytes for NEW image display
  String? _existingProfilePicUrl;
  final ImagePicker _picker = ImagePicker();

  // 🔹 1. Flags to control visibility
  // We'll show the picture section always, so the user can update it.
  bool _showPhoneField = true;
  bool _showSkillsField = true;
  bool _showLinksSection = true;
  bool _showFypSection = true;

  @override
  void initState() {
    super.initState();

    // Access the provider *without* listening
    final student = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).student;

    if (student != null) {
      // --- Pre-fill Basic Info ---
      _phoneController.text = student.user.phone ?? '';
      _skillsController.text = (student.skills ?? []).join(', ');
      _existingProfilePicUrl = student.profilePicUrl;

      // --- Pre-fill Contact Links ---
      String getLinkUrl(String platform) {
        if (student.contactLinks == null) return '';
        try {
          final link = student.contactLinks.firstWhere(
            (link) =>
                link.platform.name.toLowerCase() == platform.toLowerCase(),
          );
          return link.url ?? '';
        } catch (e) {
          return '';
        }
      }

      _linkedInController.text = getLinkUrl('LinkedIn');
      _githubController.text = getLinkUrl('GitHub');

      // --- Pre-fill Final Year Project ---
      _fypTitleController.text = student.fypTitle ?? '';
      _fypDescController.text = student.fypDescription ?? '';
      _fypDemoUrlController.text = student.fypDemoUrl ?? '';
      _fypGithubUrlController.text = student.fypGithubUrl ?? '';

      // 🔹 2. Set visibility flags based on pre-filled data
      // If the field is NOT empty, we hide it.
      _showPhoneField = _phoneController.text.isEmpty;
      _showSkillsField = _skillsController.text.isEmpty;
      // If both links are filled, hide the whole section
      _showLinksSection =
          _linkedInController.text.isEmpty || _githubController.text.isEmpty;
      // If the FYP title is filled, hide the whole section
      _showFypSection = _fypTitleController.text.isEmpty;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _skillsController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    _fypTitleController.dispose();
    _fypDescController.dispose();
    _fypDemoUrlController.dispose();
    _fypGithubUrlController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  // --- Form Submission Logic ---
  Future<void> _submitProfile() async {
    // 🔹 3. Validation only runs on visible fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Pic validation: Only require if no new one is picked AND no old one exists
    if (_pickedImage == null &&
        (_existingProfilePicUrl == null || _existingProfilePicUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a profile picture.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<StudentProvider>(context, listen: false);

    try {
      // 1. Upload Profile Pic (Only if a new one was picked)
      if (_pickedImage != null) {
        bool picSuccess = await provider.uploadProfilePic(_pickedImage!);
        if (!picSuccess) throw Exception('Profile picture upload failed.');
      }

      // 🔹 4. Only submit data for sections that were shown

      // 2. Update Phone
      if (_showPhoneField) {
        bool phoneSuccess = await provider.updatePhoneNumber(
          _phoneController.text,
        );
        if (!phoneSuccess) throw Exception('Phone number update failed.');
      }

      // 3. Add Skills
      if (_showSkillsField) {
        final skills = _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        bool skillsSuccess = await provider.addSkills(skills);
        if (!skillsSuccess) throw Exception('Skills update failed.');
      }

      // 4. Add Links (Only if the section was visible)
      if (_showLinksSection) {
        if (_linkedInController.text.isNotEmpty) {
          await provider.addContactLink({
            'platform': 'LinkedIn',
            'url': _linkedInController.text,
          });
        }
        if (_githubController.text.isNotEmpty) {
          await provider.addContactLink({
            'platform': 'GitHub',
            'url': _githubController.text,
          });
        }
      }

      // 5. Add FYP (Only if the section was visible)
      if (_showFypSection) {
        bool fypSuccess = await provider.createProject({
          'title': _fypTitleController.text,
          'description': _fypDescController.text,
          'demoUrl': _fypDemoUrlController.text,
          'gitHubUrl': _fypGithubUrlController.text,
          'type': 'FinalYear',
        });
        if (!fypSuccess) throw Exception('FYP creation failed.');
      }

      // All successful, navigate to the main profile screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the correct image to show.
    ImageProvider? displayImage;
    if (_imageBytes != null) {
      displayImage = MemoryImage(_imageBytes!);
    } else if (_existingProfilePicUrl != null &&
        _existingProfilePicUrl!.isNotEmpty) {
      displayImage = NetworkImage("$_serverBaseUrl$_existingProfilePicUrl");
    } else {
      displayImage = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    // We always show the profile pic so it can be updated
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: displayImage,
                          child: (displayImage == null)
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Colors.grey.shade700,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Basic Info ---
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),

                    // 🔹 5. Use Visibility widget
                    Visibility(
                      visible: _showPhoneField,
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number*',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          // Validator only runs if visible
                          if (_showPhoneField &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                    // Add padding if both are visible
                    if (_showPhoneField && _showSkillsField)
                      const SizedBox(height: 16),

                    Visibility(
                      visible: _showSkillsField,
                      child: TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(
                          labelText: 'Skills*',
                          hintText: 'e.g., Flutter, React, Node.js',
                        ),
                        validator: (value) {
                          if (_showSkillsField &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter at least one skill';
                          }
                          return null;
                        },
                      ),
                    ),

                    // If both fields are hidden, show a helper message
                    if (!_showPhoneField && !_showSkillsField)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Phone and skills already provided.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // --- Contact Links ---
                    Visibility(
                      visible: _showLinksSection,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Contact Links'),
                          const SizedBox(height: 16),
                          // We can show/hide individual links too
                          if (_linkedInController.text.isEmpty)
                            TextFormField(
                              controller: _linkedInController,
                              decoration: const InputDecoration(
                                labelText: 'LinkedIn Profile URL',
                                prefixIcon: Icon(Icons.link),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          if (_linkedInController.text.isEmpty &&
                              _githubController.text.isEmpty)
                            const SizedBox(height: 16),

                          if (_githubController.text.isEmpty)
                            TextFormField(
                              controller: _githubController,
                              decoration: const InputDecoration(
                                labelText: 'GitHub Profile URL',
                                prefixIcon: Icon(Icons.link),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),

                    // --- Final Year Project ---
                    Visibility(
                      visible: _showFypSection,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Final Year Project'),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fypTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Project Title*',
                            ),
                            validator: (value) {
                              if (_showFypSection &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter your project title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fypDescController,
                            decoration: const InputDecoration(
                              labelText: 'Project Description*',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (_showFypSection &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter a project description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fypDemoUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Project Demo URL',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fypGithubUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Project GitHub URL',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Submit Button ---
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Save & Continue'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}
