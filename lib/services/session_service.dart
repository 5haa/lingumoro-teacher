import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherSessionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMySessions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('sessions')
          .select('''
            *,
            student:students(id, full_name, email, avatar_url, is_online),
            language:language_courses(id, name, flag_url),
            subscription:student_subscriptions(id, points_remaining, status)
          ''')
          .eq('teacher_id', user.id)
          .order('scheduled_date')
          .order('scheduled_start_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching sessions: $e');
      throw Exception('Failed to load sessions');
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingSessions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('sessions')
          .select('''
            *,
            student:students(id, full_name, email, avatar_url, is_online),
            language:language_courses(id, name, flag_url),
            subscription:student_subscriptions(id, points_remaining, status)
          ''')
          .eq('teacher_id', user.id)
          .gte('scheduled_date', today)
          .inFilter('status', ['scheduled', 'ready'])
          .order('scheduled_date')
          .order('scheduled_start_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching upcoming sessions: $e');
      throw Exception('Failed to load upcoming sessions');
    }
  }

  Future<Map<String, dynamic>?> getTodaySession() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('sessions')
          .select('''
            *,
            student:students(id, full_name, avatar_url, is_online),
            language:language_courses(id, name)
          ''')
          .eq('teacher_id', user.id)
          .eq('scheduled_date', today)
          .inFilter('status', ['scheduled', 'ready', 'in_progress'])
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching today\'s session: $e');
      return null;
    }
  }

  Future<bool> setMeetingLink(String sessionId, String meetingLink) async {
    try {
      await _supabase
          .from('sessions')
          .update({
            'meeting_link': meetingLink,
            'status': 'ready',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      return true;
    } catch (e) {
      print('Error setting meeting link: $e');
      return false;
    }
  }

  Future<bool> startSession(String sessionId) async {
    try {
      await _supabase
          .from('sessions')
          .update({
            'status': 'in_progress',
            'actual_start_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      return true;
    } catch (e) {
      print('Error starting session: $e');
      return false;
    }
  }

  Future<bool> endSession(String sessionId) async {
    try {
      // Get session and subscription details
      final sessionResponse = await _supabase
          .from('sessions')
          .select('*, subscription:student_subscriptions(id, points_remaining)')
          .eq('id', sessionId)
          .single();

      final subscription = sessionResponse['subscription'];
      
      // End the session
      await _supabase
          .from('sessions')
          .update({
            'status': 'completed',
            'actual_end_time': DateTime.now().toIso8601String(),
            'point_deducted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      // Deduct a point from the subscription
      if (subscription != null) {
        final currentPoints = subscription['points_remaining'] as int;
        final newPoints = currentPoints - 1;
        
        await _supabase
          .from('student_subscriptions')
          .update({
            'points_remaining': newPoints,
            'status': newPoints <= 0 ? 'expired' : 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscription['id']);
      }

      return true;
    } catch (e) {
      print('Error ending session: $e');
      return false;
    }
  }

  Future<bool> cancelSession(String sessionId, String reason) async {
    try {
      await _supabase
          .from('sessions')
          .update({
            'status': 'cancelled',
            'teacher_notes': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      return true;
    } catch (e) {
      print('Error cancelling session: $e');
      return false;
    }
  }

  bool canManageSession(Map<String, dynamic> session) {
    // Can manage if session is upcoming or in progress
    final status = session['status'];
    return status == 'scheduled' || status == 'ready' || status == 'in_progress';
  }

  String getSessionStatus(Map<String, dynamic> session) {
    try {
      final now = DateTime.now();
      final scheduledDate = DateTime.parse(session['scheduled_date']);
      final scheduledTime = _parseTime(session['scheduled_start_time']);
      
      final scheduledDateTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledTime['hour']!,
        scheduledTime['minute']!,
      );

      if (session['status'] == 'in_progress') {
        return 'In Progress';
      } else if (now.isAfter(scheduledDateTime)) {
        return 'Missed';
      } else {
        return 'Upcoming';
      }
    } catch (e) {
      return session['status'] ?? 'Unknown';
    }
  }

  Map<String, int> _parseTime(String timeString) {
    final parts = timeString.split(':');
    return {
      'hour': int.parse(parts[0]),
      'minute': int.parse(parts[1]),
    };
  }
}

