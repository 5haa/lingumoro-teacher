import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:teacher/services/auth_service.dart';
import 'package:teacher/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../config/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/error_helper.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_back_button.dart';
import '../../l10n/app_localizations.dart';

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
    _specializationController = TextEditingController(text: widget.profile['specialization'] ?? '');
    _bioController = TextEditingController(text: widget.profile['bio'] ?? '');
    _introVideoController = TextEditingController(text: widget.profile['intro_video_url'] ?? '');
    _meetingLinkController = TextEditingController(text: widget.profile['meeting_link'] ?? '');
    _currentAvatarUrl = widget.profile['avatar_url'];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
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
            content: Text(ErrorHelper.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).chooseProfilePicture,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.images,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context).chooseFromGallery,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.camera,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context).takeAPhoto,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_currentAvatarUrl != null || _newAvatarFile != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.trash,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context).removePhoto,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
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
      
      // Clear old avatar from cache if uploading a new one
      if (_newAvatarFile != null && _currentAvatarUrl != null) {
        final cacheManager = DefaultCacheManager();
        await cacheManager.removeFile(_currentAvatarUrl!);
        print('🗑️ Cleared old avatar from cache');
      }
      
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
        'specialization': _specializationController.text.trim().isEmpty ? null : _specializationController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'intro_video_url': _introVideoController.text.trim().isEmpty ? null : _introVideoController.text.trim(),
        'meeting_link': _meetingLinkController.text.trim().isEmpty ? null : _meetingLinkController.text.trim(),
        'avatar_url': avatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profileUpdatedSuccessfully),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHelper.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
    final fullName = widget.profile['full_name'] ?? 'Teacher';
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : 'T';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                
                // Avatar Section
                _buildAvatarSection(initials),
                
                const SizedBox(height: 20),
                
                // Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Full Name
                        CustomTextField(
                          labelText: AppLocalizations.of(context).fullName,
                          hintText: AppLocalizations.of(context).enterYourFullName,
                          controller: _fullNameController,
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.user,
                            size: 18,
                            color: AppColors.grey,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context).pleaseEnterYourName;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Specialization
                        CustomTextField(
                          labelText: AppLocalizations.of(context).specialization,
                          hintText: AppLocalizations.of(context).specializationExample,
                          controller: _specializationController,
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.graduationCap,
                            size: 18,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bio
                        CustomTextField(
                          labelText: AppLocalizations.of(context).bio,
                          hintText: AppLocalizations.of(context).tellStudentsAboutYourself,
                          controller: _bioController,
                          maxLines: 4,
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.info,
                            size: 18,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Intro Video URL
                        CustomTextField(
                          labelText: AppLocalizations.of(context).introductionVideoYouTubeUrl,
                          hintText: AppLocalizations.of(context).youtubeUrlHint,
                          controller: _introVideoController,
                          keyboardType: TextInputType.url,
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.video,
                            size: 18,
                            color: AppColors.grey,
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              if (!value.contains('youtube.com') && !value.contains('youtu.be')) {
                                return AppLocalizations.of(context).pleaseEnterValidYouTubeUrl;
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Meeting Link
                        CustomTextField(
                          labelText: AppLocalizations.of(context).defaultMeetingLink,
                          hintText: AppLocalizations.of(context).zoomGoogleMeetEtc,
                          controller: _meetingLinkController,
                          keyboardType: TextInputType.url,
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.video,
                            size: 18,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Save Button
                        CustomButton(
                          text: AppLocalizations.of(context).saveChanges,
                          onPressed: _isLoading ? () {} : _saveProfile,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const CustomBackButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String initials) {
    return Column(
      children: [
        // Avatar Image
        Center(
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _isUploadingAvatar
                        ? Container(
                            color: AppColors.lightGrey,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          )
                        : _newAvatarFile != null
                            ? Image.file(
                                _newAvatarFile!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              )
                            : _currentAvatarUrl != null
                                ? CachedNetworkImage(
                                    key: ValueKey(_currentAvatarUrl),
                                    imageUrl: _currentAvatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.lightGrey,
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.lightGrey,
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.lightGrey,
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                  ),
                ),
                // Camera Icon Overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Add/Change Photo Button
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploadingAvatar)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  FaIcon(
                    _currentAvatarUrl == null && _newAvatarFile == null
                        ? FontAwesomeIcons.camera
                        : FontAwesomeIcons.penToSquare,
                    size: 16,
                    color: AppColors.primary,
                  ),
                const SizedBox(width: 8),
                Text(
                  _currentAvatarUrl == null && _newAvatarFile == null
                      ? AppLocalizations.of(context).addPhoto
                      : AppLocalizations.of(context).changePhoto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
