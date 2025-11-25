import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleService {
  final _supabase = Supabase.instance.client;

  /// Fetch teacher's schedules
  Future<List<Map<String, dynamic>>> getTeacherSchedules(String teacherId) async {
    try {
      final response = await _supabase
          .from('teacher_schedules')
          .select()
          .eq('teacher_id', teacherId)
          .order('day_of_week', ascending: true)
          .order('start_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching teacher schedules: $e');
      return [];
    }
  }

  /// Add a schedule slot
  /// Returns a Map with 'success' (bool) and optional 'message' (String)
  Future<Map<String, dynamic>> addSchedule({
    required String teacherId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // Add the schedule
      await _supabase.from('teacher_schedules').insert({
        'teacher_id': teacherId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_available': true,
      });

      // Auto-generate 30-minute timeslots
      await _supabase.rpc('generate_timeslots_for_range', params: {
        'p_teacher_id': teacherId,
        'p_day_of_week': dayOfWeek,
        'p_start_time': startTime,
        'p_end_time': endTime,
      });

      return {'success': true};
    } catch (e) {
      print('Error adding schedule: $e');
      
      // Check if it's a duplicate key error
      if (e is PostgrestException && e.code == '23505') {
        return {
          'success': false,
          'message': 'This time slot already exists for the selected day. Please choose a different time or day.',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to add schedule. Please try again.',
      };
    }
  }

  /// Delete a schedule slot
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _supabase
          .from('teacher_schedules')
          .delete()
          .eq('id', scheduleId);

      return true;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  /// Toggle schedule availability
  Future<bool> toggleSchedule(String scheduleId, bool isAvailable) async {
    try {
      await _supabase
          .from('teacher_schedules')
          .update({'is_available': isAvailable})
          .eq('id', scheduleId);

      return true;
    } catch (e) {
      print('Error toggling schedule: $e');
      return false;
    }
  }
}



