import 'package:supabase_flutter/supabase_flutter.dart';

class TimeslotService {
  final _supabase = Supabase.instance.client;

  /// Get all timeslots for a teacher grouped by day
  Future<Map<int, List<Map<String, dynamic>>>> getTeacherTimeslots(
    String teacherId,
  ) async {
    try {
      final response = await _supabase
          .from('teacher_timeslots')
          .select()
          .eq('teacher_id', teacherId)
          .order('day_of_week')
          .order('start_time');

      final slots = List<Map<String, dynamic>>.from(response);

      // Group by day
      final Map<int, List<Map<String, dynamic>>> groupedSlots = {};
      for (var slot in slots) {
        final day = slot['day_of_week'] as int;
        if (!groupedSlots.containsKey(day)) {
          groupedSlots[day] = [];
        }
        groupedSlots[day]!.add(slot);
      }

      return groupedSlots;
    } catch (e) {
      print('Error fetching teacher timeslots: $e');
      return {};
    }
  }

  /// Get timeslots for a specific day
  Future<List<Map<String, dynamic>>> getTimeslotsForDay(
    String teacherId,
    int dayOfWeek,
  ) async {
    try {
      final response = await _supabase
          .from('teacher_timeslots')
          .select()
          .eq('teacher_id', teacherId)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching timeslots for day: $e');
      return [];
    }
  }

  /// Toggle a specific timeslot's availability
  Future<bool> toggleTimeslot(String timeslotId, bool isAvailable) async {
    try {
      await _supabase
          .from('teacher_timeslots')
          .update({'is_available': isAvailable, 'updated_at': 'now()'})
          .eq('id', timeslotId);

      return true;
    } catch (e) {
      print('Error toggling timeslot: $e');
      return false;
    }
  }

  /// Bulk toggle timeslots
  Future<bool> bulkToggleTimeslots(
    List<String> timeslotIds,
    bool isAvailable,
  ) async {
    try {
      await _supabase
          .from('teacher_timeslots')
          .update({'is_available': isAvailable, 'updated_at': 'now()'})
          .inFilter('id', timeslotIds);

      return true;
    } catch (e) {
      print('Error bulk toggling timeslots: $e');
      return false;
    }
  }

  /// Get timeslot statistics
  Future<Map<String, int>> getTimeslotStats(String teacherId) async {
    try {
      final response = await _supabase
          .from('teacher_timeslots')
          .select()
          .eq('teacher_id', teacherId);

      final slots = List<Map<String, dynamic>>.from(response);

      return {
        'total': slots.length,
        'available': slots
            .where((s) =>
                s['is_available'] == true && s['is_occupied'] == false)
            .length,
        'disabled': slots.where((s) => s['is_available'] == false).length,
        'occupied': slots.where((s) => s['is_occupied'] == true).length,
      };
    } catch (e) {
      print('Error fetching timeslot stats: $e');
      return {'total': 0, 'available': 0, 'disabled': 0, 'occupied': 0};
    }
  }

  /// Generate timeslots for a schedule (called when teacher adds time range)
  Future<bool> generateTimeslotsForSchedule(
    String teacherId,
    int dayOfWeek,
    String startTime,
    String endTime,
  ) async {
    try {
      await _supabase.rpc('generate_timeslots_for_range', params: {
        'p_teacher_id': teacherId,
        'p_day_of_week': dayOfWeek,
        'p_start_time': startTime,
        'p_end_time': endTime,
      });

      return true;
    } catch (e) {
      print('Error generating timeslots: $e');
      return false;
    }
  }

  /// Delete timeslots for a schedule (called when teacher deletes time range)
  Future<bool> deleteTimeslotsForSchedule(
    String teacherId,
    int dayOfWeek,
    String startTime,
    String endTime,
  ) async {
    try {
      await _supabase
          .from('teacher_timeslots')
          .delete()
          .eq('teacher_id', teacherId)
          .eq('day_of_week', dayOfWeek)
          .gte('start_time', startTime)
          .lt('start_time', endTime);

      return true;
    } catch (e) {
      print('Error deleting timeslots: $e');
      return false;
    }
  }
}


















