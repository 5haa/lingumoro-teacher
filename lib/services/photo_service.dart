import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoService {
  final _supabase = Supabase.instance.client;

  /// Get all photos for a student
  Future<List<Map<String, dynamic>>> getStudentPhotos(String studentId) async {
    try {
      final photos = await _supabase
          .from('student_photos')
          .select()
          .eq('student_id', studentId)
          .order('is_main', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(photos);
    } catch (e) {
      print('Error fetching student photos: $e');
      return [];
    }
  }

  /// Get main photo for a student
  Future<Map<String, dynamic>?> getMainPhoto(String studentId) async {
    try {
      final photos = await _supabase
          .from('student_photos')
          .select()
          .eq('student_id', studentId)
          .eq('is_main', true)
          .limit(1);

      if (photos.isNotEmpty) {
        return photos[0] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching main photo: $e');
      return null;
    }
  }
}

