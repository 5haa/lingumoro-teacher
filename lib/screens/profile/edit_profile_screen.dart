import 'dart:io';
import 'package:flutter/material.dart';
import 'package:teacher/services/auth_service.dart';
import 'package:teacher/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _storageService = StorageService();
  
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _bioController;
  late TextEditingController _introVideoController;
  late TextEditingController _meetingLinkController;
  
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  File? _newAvatarFile;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile['full_name'] ?? '');
    _phoneController = TextEditingController(text: widget.profile['phone'] ?? '');
    _specializationController = TextEditingController(text: widget.profile['specialization'] ?? '');
    _bioController = TextEditingController(text: widget.profile['bio'] ?? '');
    _introVideoController = TextEditingController(text: widget.profile['intro_video_url'] ?? '');
    _meetingLinkController = TextEditingController(text: widget.profile['meeting_link'] ?? '');
    _currentAvatarUrl = widget.profile['avatar_url'];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _introVideoController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isUploadingAvatar = true);
      
      final file = await _storageService.pickImage(source: source);
      if (file != null) {
        setState(() {
          _newAvatarFile = file;
          _isUploadingAvatar = false;
        });
      } else {
        setState(() => _isUploadingAvatar = false);
      }
    } catch (e) {
      setState(() => _isUploadingAvatar = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_currentAvatarUrl != null || _newAvatarFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _newAvatarFile = null;
                      _currentAvatarUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? avatarUrl = _currentAvatarUrl;
      
      // Upload new avatar if selected
      if (_newAvatarFile != null) {
        final teacherId = _authService.currentUser?.id;
        if (teacherId != null) {
          avatarUrl = await _storageService.uploadTeacherAvatar(
            teacherId: teacherId,
            imageFile: _newAvatarFile!,
          );
        }
      }
      
      await _authService.updateTeacherProfile({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'specialization': _specializationController.text.trim().isEmpty ? null : _specializationController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'intro_video_url': _introVideoController.text.trim().isEmpty ? null : _introVideoController.text.trim(),
        'meeting_link': _meetingLinkController.text.trim().isEmpty ? null : _meetingLinkController.text.trim(),
        'avatar_url': avatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          child: _isUploadingAvatar
                              ? const CircularProgressIndicator()
                              : _newAvatarFile != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _newAvatarFile!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _currentAvatarUrl != null
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: _currentAvatarUrl!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const CircularProgressIndicator(),
                                            errorWidget: (context, url, error) => Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(
                      _currentAvatarUrl == null && _newAvatarFile == null
                          ? 'Add Profile Picture'
                          : 'Change Profile Picture',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: const Icon(Icons.person, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Specialization
            TextFormField(
              controller: _specializationController,
              decoration: InputDecoration(
                labelText: 'Specialization',
                prefixIcon: const Icon(Icons.school, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'e.g., English Literature, Math',
              ),
            ),
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                prefixIcon: const Icon(Icons.info, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'Tell students about yourself...',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 16),

            // Intro Video URL
            TextFormField(
              controller: _introVideoController,
              decoration: InputDecoration(
                labelText: 'Introduction Video (YouTube URL)',
                prefixIcon: const Icon(Icons.video_library, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'https://www.youtube.com/watch?v=...',
                helperText: 'Add a YouTube video to introduce yourself to students',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Basic YouTube URL validation
                  if (!value.contains('youtube.com') && !value.contains('youtu.be')) {
                    return 'Please enter a valid YouTube URL';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Meeting Link
            TextFormField(
              controller: _meetingLinkController,
              decoration: InputDecoration(
                labelText: 'Default Meeting Link',
                prefixIcon: const Icon(Icons.videocam, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'Zoom, Google Meet, etc.',
                helperText: 'Default meeting link for sessions with students',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
























