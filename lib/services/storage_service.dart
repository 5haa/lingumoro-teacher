import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Upload teacher avatar
  Future<String?> uploadTeacherAvatar({
    required String teacherId,
    required File imageFile,
  }) async {
    try {
      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final filePath = '$teacherId/$fileName';

      // Upload to storage
      await _supabase.storage
          .from('teacher-avatars')
          .upload(filePath, imageFile);

      // Get public URL
      final avatarUrl = _supabase.storage
          .from('teacher-avatars')
          .getPublicUrl(filePath);

      return avatarUrl;
    } catch (e) {
      print('Error uploading teacher avatar: $e');
      return null;
    }
  }

  /// Delete teacher avatar from storage
  Future<bool> deleteTeacherAvatar(String avatarUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the index where 'teacher-avatars' appears
      final bucketIndex = pathSegments.indexOf('teacher-avatars');
      if (bucketIndex == -1) return false;
      
      // Get the file path after the bucket name
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage
          .from('teacher-avatars')
          .remove([filePath]);

      return true;
    } catch (e) {
      print('Error deleting teacher avatar: $e');
      return false;
    }
  }
}









