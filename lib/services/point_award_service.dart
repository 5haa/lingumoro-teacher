import 'package:supabase_flutter/supabase_flutter.dart';

class PointAwardService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  /// Get list of students enrolled with the teacher
  Future<List<Map<String, dynamic>>> getMyStudents() async {
    try {
      if (currentUser == null) {
        print('No user logged in');
        return [];
      }

      // Get students who have active or completed subscriptions with this teacher
      final subscriptions = await _supabase
          .from('student_subscriptions')
          .select('*, students(id, full_name, email, avatar_url, level, points)')
          .eq('teacher_id', currentUser!.id)
          .inFilter('status', ['active', 'completed']);

      // Extract unique students and calculate awarded points
      final Map<String, Map<String, dynamic>> studentsMap = {};
      
      for (final subscription in subscriptions) {
        final student = subscription['students'];
        if (student != null && !studentsMap.containsKey(student['id'])) {
          // Get total points awarded by this teacher to this student
          final awards = await _supabase
              .from('teacher_point_awards')
              .select('points_awarded')
              .eq('teacher_id', currentUser!.id)
              .eq('student_id', student['id']);
          
          int totalAwarded = 0;
          for (final award in awards) {
            totalAwarded += (award['points_awarded'] as int?) ?? 0;
          }
          
          student['total_points_awarded_by_me'] = totalAwarded;
          studentsMap[student['id']] = student;
        }
      }

      return studentsMap.values.toList();
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  /// Get point award settings/limits
  Future<Map<String, int>?> getPointSettings() async {
    try {
      final settings = await _supabase
          .from('system_settings')
          .select()
          .inFilter('setting_key', [
            'max_points_per_student_total',
            'max_points_per_award',
            'max_points_per_day',
            'max_points_per_week'
          ]);

      final Map<String, int> settingsMap = {};
      for (final setting in settings) {
        settingsMap[setting['setting_key']] = int.parse(setting['setting_value']);
      }

      return settingsMap;
    } catch (e) {
      print('Error getting settings: $e');
      return null;
    }
  }

  /// Award points to a student
  Future<Map<String, dynamic>?> awardPoints({
    required String studentId,
    required int points,
    required String note,
  }) async {
    try {
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      // Get settings
      final settings = await getPointSettings();
      if (settings == null) {
        return {
          'success': false,
          'error': 'Failed to load settings',
        };
      }

      final maxPerStudent = settings['max_points_per_student_total'] ?? 500;
      final maxPerAward = settings['max_points_per_award'] ?? 50;
      final maxPerDay = settings['max_points_per_day'] ?? 100;
      final maxPerWeek = settings['max_points_per_week'] ?? 300;

      // Validate points against max per award
      if (points > maxPerAward) {
        return {
          'success': false,
          'error': 'Maximum points per award is $maxPerAward',
        };
      }

      // Check total points already awarded to this student
      final totalAwards = await _supabase
          .from('teacher_point_awards')
          .select('points_awarded')
          .eq('teacher_id', currentUser!.id)
          .eq('student_id', studentId);

      int currentTotal = 0;
      for (final award in totalAwards) {
        currentTotal += (award['points_awarded'] as int?) ?? 0;
      }

      if ((currentTotal + points) > maxPerStudent) {
        return {
          'success': false,
          'error': 'You have already awarded $currentTotal points to this student. Maximum is $maxPerStudent points per student.',
        };
      }

      // Check daily limit
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayAwards = await _supabase
          .from('teacher_point_awards')
          .select('points_awarded')
          .eq('teacher_id', currentUser!.id)
          .gte('created_at', todayStart.toIso8601String())
          .lt('created_at', todayEnd.toIso8601String());

      int todayTotal = 0;
      for (final award in todayAwards) {
        todayTotal += (award['points_awarded'] as int?) ?? 0;
      }

      if ((todayTotal + points) > maxPerDay) {
        return {
          'success': false,
          'error': 'You have already awarded $todayTotal points today. Daily limit is $maxPerDay points.',
        };
      }

      // Check weekly limit
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEnd = weekStartDate.add(const Duration(days: 7));

      final weekAwards = await _supabase
          .from('teacher_point_awards')
          .select('points_awarded')
          .eq('teacher_id', currentUser!.id)
          .gte('created_at', weekStartDate.toIso8601String())
          .lt('created_at', weekEnd.toIso8601String());

      int weekTotal = 0;
      for (final award in weekAwards) {
        weekTotal += (award['points_awarded'] as int?) ?? 0;
      }

      if ((weekTotal + points) > maxPerWeek) {
        return {
          'success': false,
          'error': 'You have already awarded $weekTotal points this week. Weekly limit is $maxPerWeek points.',
        };
      }

      // Verify student has subscription with this teacher
      final subscription = await _supabase
          .from('student_subscriptions')
          .select('id')
          .eq('teacher_id', currentUser!.id)
          .eq('student_id', studentId)
          .inFilter('status', ['active', 'completed'])
          .maybeSingle();

      if (subscription == null) {
        return {
          'success': false,
          'error': 'Student is not enrolled with you',
        };
      }

      // Create point award record
      final award = await _supabase.from('teacher_point_awards').insert({
        'teacher_id': currentUser!.id,
        'student_id': studentId,
        'points_awarded': points,
        'note': note,
      }).select().single();

      // Update student points and level
      final student = await _supabase
          .from('students')
          .select('points, level')
          .eq('id', studentId)
          .single();

      final currentPoints = (student['points'] as int?) ?? 0;
      final newPoints = currentPoints + points;
      
      // Calculate new level (100 points per level)
      final newLevel = ((newPoints / 100).floor() + 1).clamp(1, 100);

      await _supabase.from('students').update({
        'points': newPoints,
        'level': newLevel,
      }).eq('id', studentId);

      return {
        'success': true,
        'message': 'Points awarded successfully',
        'award': award,
        'new_points': newPoints,
        'new_level': newLevel,
      };
    } catch (e) {
      print('Error awarding points: $e');
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get award history for the teacher
  Future<List<Map<String, dynamic>>> getAwardHistory() async {
    try {
      if (currentUser == null) {
        print('No user logged in');
        return [];
      }

      final awards = await _supabase
          .from('teacher_point_awards')
          .select('*, students(id, full_name, email, avatar_url)')
          .eq('teacher_id', currentUser!.id)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(awards);
    } catch (e) {
      print('Error getting award history: $e');
      return [];
    }
  }

  /// Get awards given to a specific student
  Future<List<Map<String, dynamic>>> getStudentAwards(String studentId) async {
    try {
      if (currentUser == null) {
        print('No user logged in');
        return [];
      }

      final awards = await _supabase
          .from('teacher_point_awards')
          .select()
          .eq('teacher_id', currentUser!.id)
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(awards);
    } catch (e) {
      print('Error getting student awards: $e');
      return [];
    }
  }
}

