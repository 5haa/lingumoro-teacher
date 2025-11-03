import 'package:supabase_flutter/supabase_flutter.dart';

class LanguageService {
  final _supabase = Supabase.instance.client;

  /// Fetch languages for a specific teacher
  Future<List<Map<String, dynamic>>> getTeacherLanguages(String teacherId) async {
    try {
      final response = await _supabase
          .from('teacher_languages')
          .select('*, language_courses(*)')
          .eq('teacher_id', teacherId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching teacher languages: $e');
      return [];
    }
  }

  /// Fetch all active language courses
  Future<List<Map<String, dynamic>>> getAllLanguages() async {
    try {
      final response = await _supabase
          .from('language_courses')
          .select()
          .eq('is_active', true)
          .order('order_index', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching language courses: $e');
      return [];
    }
  }
}
