import 'package:supabase_flutter/supabase_flutter.dart';

class RatingService {
  final _supabase = Supabase.instance.client;

  /// Get teacher rating statistics
  Future<Map<String, dynamic>?> getTeacherRatingStats(String teacherId) async {
    try {
      final response = await _supabase
          .from('teacher_rating_stats')
          .select()
          .eq('teacher_id', teacherId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching teacher rating stats: $e');
      return null;
    }
  }

  /// Get all ratings for a teacher
  Future<List<Map<String, dynamic>>> getTeacherRatings(String teacherId) async {
    try {
      final response = await _supabase
          .from('teacher_ratings')
          .select('''
            *,
            students:student_id (
              full_name,
              avatar_url
            )
          ''')
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching teacher ratings: $e');
      return [];
    }
  }

  /// Get current teacher's rating statistics
  Future<Map<String, dynamic>?> getMyRatingStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      return await getTeacherRatingStats(user.id);
    } catch (e) {
      print('Error fetching my rating stats: $e');
      return null;
    }
  }

  /// Get current teacher's ratings
  Future<List<Map<String, dynamic>>> getMyRatings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      return await getTeacherRatings(user.id);
    } catch (e) {
      print('Error fetching my ratings: $e');
      return [];
    }
  }
}























