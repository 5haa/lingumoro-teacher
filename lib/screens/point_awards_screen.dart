import 'package:flutter/material.dart';
import 'package:teacher/services/point_award_service.dart';
import '../l10n/app_localizations.dart';

class PointAwardsScreen extends StatefulWidget {
  const PointAwardsScreen({super.key});

  @override
  State<PointAwardsScreen> createState() => _PointAwardsScreenState();
}

class _PointAwardsScreenState extends State<PointAwardsScreen> {
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _pointAwardService.getMyStudents();
      final settings = await _pointAwardService.getPointSettings();

      if (mounted) {
        setState(() {
          _students = students;
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    }
  }

  void _showAwardDialog(Map<String, dynamic> student) {
    final pointsController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
        title: Text('${l10n.awardPointsTo} ${student['full_name']}'),
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.currentLevelLabel} ${student['level'] ?? 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('${l10n.currentPointsLabel} ${student['points'] ?? 0}'),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.pointsAwardedByYou} ${student['total_points_awarded_by_me'] ?? 0}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
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
                        Text(
                          l10n.pointLimits,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('${l10n.maxPerAward} ${_settings!['max_points_per_award']}'),
                        Text('${l10n.maxPerStudent} ${_settings!['max_points_per_student_total']}'),
                        Text('${l10n.maxPerDay} ${_settings!['max_points_per_day']}'),
                        Text('${l10n.maxPerWeek} ${_settings!['max_points_per_week']}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Points input
                TextFormField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.pointsToAward,
                    hintText: l10n.enterPoints,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPoints;
                    }
                    final points = int.tryParse(value);
                    if (points == null || points <= 0) {
                      return l10n.enterValidPositiveNumber;
                    }
                    if (_settings != null && points > _settings!['max_points_per_award']!) {
                      return l10n.maxPointsPerAward.replaceAll('{max}', _settings!['max_points_per_award'].toString());
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
                  decoration: InputDecoration(
                    labelText: l10n.note,
                    hintText: l10n.whyAwardingPoints,
                    border: const OutlineInputBorder(),
                    helperText: l10n.explainWhyEarned,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterNote;
                    }
                    if (value.length < 10) {
                      return l10n.noteMinLength;
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
            child: Text(l10n.cancel),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.awardPoints),
          ),
        ],
      );
      },
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
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.pointsAwardedSuccessfully} ${result['new_level']}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reload data
          _loadData();
        } else {
          // Show error message
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['error'] ?? l10n.failedToAwardPoints),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        final errorMessage = e.toString().replaceAll(RegExp(r'^Exception: '), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).awardPointsToStudents),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                        ElevatedButton(
                        onPressed: _loadData,
                        child: Text(AppLocalizations.of(context).retry),
                      ),
                    ],
                  ),
                )
              : _students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).noStudentsEnrolled,
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.teal.shade100,
                                backgroundImage: student['avatar_url'] != null
                                    ? NetworkImage(student['avatar_url'])
                                    : null,
                                child: student['avatar_url'] == null
                                    ? Text(
                                        (student['full_name'] ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                student['full_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(student['email'] ?? ''),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${AppLocalizations.of(context).levelLabel} ${student['level'] ?? 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
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
                                          '${student['points'] ?? 0} ${AppLocalizations.of(context).pts}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (student['total_points_awarded_by_me'] > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${AppLocalizations.of(context).awardedByYou} ${student['total_points_awarded_by_me']} ${AppLocalizations.of(context).pts}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () => _showAwardDialog(student),
                                icon: const Icon(Icons.star, size: 18),
                                label: Text(AppLocalizations.of(context).award),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

