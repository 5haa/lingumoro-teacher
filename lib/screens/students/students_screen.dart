import 'package:flutter/material.dart';
import 'package:teacher/config/app_colors.dart';
import 'package:teacher/services/point_award_service.dart';
import 'package:teacher/widgets/student_avatar_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _pointAwardService = PointAwardService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  Map<String, int>? _settings;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading students...');
      final students = await _pointAwardService.getMyStudents().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Timeout loading students');
          throw Exception('Request timed out. Please check your internet connection.');
        },
      );
      
      final settings = await _pointAwardService.getPointSettings();
      
      print('Loaded ${students.length} students');

      if (mounted) {
        setState(() {
          _students = students;
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading students: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load students: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No students enrolled yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Students will appear here once they subscribe to your courses',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: StudentAvatarWidget(
                                avatarUrl: student['avatar_url'],
                                fullName: student['full_name'] ?? 'Student',
                                size: 56,
                                backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                              ),
                              title: Text(
                                student['full_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    student['email'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Level ${student['level'] ?? 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${student['points'] ?? 0} pts',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((student['total_points_awarded_by_me'] ?? 0) > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Awarded by you: ${student['total_points_awarded_by_me']} pts',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () => _showAwardDialog(student),
                                icon: const Icon(Icons.star, size: 18),
                                label: const Text('Award'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showAwardDialog(Map<String, dynamic> student) {
    final pointsController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Award Points to ${student['full_name']}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Level: ${student['level'] ?? 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Current Points: ${student['points'] ?? 0}'),
                      const SizedBox(height: 4),
                      Text(
                        'Points awarded by you: ${student['total_points_awarded_by_me'] ?? 0}',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Limits info
                if (_settings != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Point Limits:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Max per award: ${_settings!['max_points_per_award']}'),
                        Text('Max per student: ${_settings!['max_points_per_student_total']}'),
                        Text('Max per day: ${_settings!['max_points_per_day']}'),
                        Text('Max per week: ${_settings!['max_points_per_week']}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Points input
                TextFormField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points to Award *',
                    hintText: 'Enter points',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter points';
                    }
                    final points = int.tryParse(value);
                    if (points == null || points <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    if (_settings != null && points > _settings!['max_points_per_award']!) {
                      return 'Max ${_settings!['max_points_per_award']} points per award';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Note input
                TextFormField(
                  controller: noteController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Note *',
                    hintText: 'Why are you awarding these points?',
                    border: OutlineInputBorder(),
                    helperText: 'Explain why the student earned these points',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a note';
                    }
                    if (value.length < 10) {
                      return 'Note must be at least 10 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _awardPoints(
                  student['id'],
                  int.parse(pointsController.text),
                  noteController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Award Points'),
          ),
        ],
      ),
    );
  }

  Future<void> _awardPoints(String studentId, int points, String note) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _pointAwardService.awardPoints(
        studentId: studentId,
        points: points,
        note: note,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result != null && result['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Points awarded successfully! New level: ${result['new_level']}',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          
          // Reload data
          _loadData();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['error'] ?? 'Failed to award points'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
