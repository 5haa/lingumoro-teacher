import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../services/session_service.dart';
import '../../services/auth_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeacherSessionService _sessionService = TeacherSessionService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _finishedSessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final allSessions = await _sessionService.getMySessions();
      final now = DateTime.now();
      
      final upcoming = <Map<String, dynamic>>[];
      final finished = <Map<String, dynamic>>[];
      
      for (var session in allSessions) {
        try {
          final scheduledDate = DateTime.parse(session['scheduled_date']);
          final startTime = session['scheduled_start_time'] ?? '00:00:00';
          final timeParts = startTime.split(':');
          final scheduledDateTime = DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
          
          final status = session['status'] ?? '';
          if (status == 'completed' || status == 'cancelled' || 
              (scheduledDateTime.isBefore(now) && status != 'in_progress')) {
            finished.add(session);
          } else {
            upcoming.add(session);
          }
        } catch (e) {
          // If parsing fails, check status
          final status = session['status'] ?? '';
          if (status == 'completed' || status == 'cancelled') {
            finished.add(session);
          } else {
            upcoming.add(session);
          }
        }
      }
      
      // Sort upcoming by date/time (closest first)
      upcoming.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['scheduled_date']);
          final dateB = DateTime.parse(b['scheduled_date']);
          if (dateA != dateB) return dateA.compareTo(dateB);
          
          final timeA = a['scheduled_start_time'] ?? '00:00:00';
          final timeB = b['scheduled_start_time'] ?? '00:00:00';
          return timeA.compareTo(timeB);
        } catch (e) {
          return 0;
        }
      });
      
      // Sort finished by date/time (most recent first)
      finished.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['scheduled_date']);
          final dateB = DateTime.parse(b['scheduled_date']);
          if (dateA != dateB) return dateB.compareTo(dateA);
          
          final timeA = a['scheduled_start_time'] ?? '00:00:00';
          final timeB = b['scheduled_start_time'] ?? '00:00:00';
          return timeB.compareTo(timeA);
        } catch (e) {
          return 0;
        }
      });
      
      setState(() {
        _upcomingSessions = upcoming;
        _finishedSessions = finished;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sessions: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setMeetingLink(Map<String, dynamic> session) async {
    final linkController = TextEditingController(
      text: session['meeting_link'] ?? '',
    );
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Meeting Link'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            hintText: 'Enter meeting link (Zoom, Google Meet, etc.)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, linkController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      final success = await _sessionService.setMeetingLink(session['id'], result);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting link updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadSessions();
      }
    }
  }

  Future<void> _startSession(Map<String, dynamic> session) async {
    final success = await _sessionService.startSession(session['id']);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session started'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadSessions();
    }
  }

  Future<void> _endSession(Map<String, dynamic> session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await _sessionService.endSession(session['id']);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session ended successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadSessions();
      }
    }
  }

  Future<void> _joinSession(Map<String, dynamic> session) async {
    final meetingLink = session['meeting_link'];
    if (meetingLink == null || meetingLink.toString().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set a meeting link first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      String url = meetingLink.toString().trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        'MY CLASSES',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Finished'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      color: AppColors.primary,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildClassesList(_upcomingSessions, isUpcoming: true),
                          _buildClassesList(_finishedSessions, isUpcoming: false),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList(List<Map<String, dynamic>> classes,
      {required bool isUpcoming}) {
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.calendarXmark,
              size: 50,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isUpcoming ? 'No upcoming classes' : 'No finished classes',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        return _buildClassCard(classes[index], isUpcoming: isUpcoming);
      },
    );
  }

  Widget _buildClassCard(Map<String, dynamic> session,
      {required bool isUpcoming}) {
    final student = session['student'] ?? {};
    final language = session['language'] ?? {};
    final status = session['status'] ?? '';

    final scheduledDate = DateTime.parse(session['scheduled_date']);
    final dateStr = '${_getWeekday(scheduledDate.weekday)}, ${scheduledDate.day}';
    final monthStr = '${_getMonth(scheduledDate.month)} ${scheduledDate.year}';
    final startTime = session['scheduled_start_time']?.substring(0, 5) ?? '00:00';
    final endTime = session['scheduled_end_time']?.substring(0, 5) ?? '00:00';
    final timeStr = '$startTime - $endTime';

    // Calculate duration
    String duration = '45 min';
    try {
      final start = DateTime.parse('2000-01-01 ${session['scheduled_start_time']}');
      final end = DateTime.parse('2000-01-01 ${session['scheduled_end_time']}');
      final diff = end.difference(start).inMinutes;
      duration = '$diff min';
    } catch (e) {
      // Keep default
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language and Status
          Row(
            children: [
              // Language Flag
              if (language['flag_url'] != null)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: language['flag_url'],
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.language,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.greenGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  language['name'] ?? 'Language',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Student Info
          Row(
            children: [
              ClipOval(
                child: student['avatar_url'] != null
                    ? CachedNetworkImage(
                        imageUrl: student['avatar_url'],
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _buildStudentAvatar(student),
                      )
                    : _buildStudentAvatar(student),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['full_name'] ?? 'Student',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (student['email'] != null)
                      Text(
                        student['email'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Date and Time
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.calendar,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dateStr $monthStr',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.clock,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          // Actions (only for upcoming)
          if (isUpcoming) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (status == 'scheduled' || status == 'ready') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setMeetingLink(session),
                      icon: const FaIcon(FontAwesomeIcons.link, size: 12),
                      label: Text(
                        session['meeting_link'] != null && session['meeting_link'].toString().isNotEmpty
                            ? 'Update Link'
                            : 'Set Link',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (status == 'ready' || status == 'in_progress') ...[
                  if (session['meeting_link'] != null && session['meeting_link'].toString().isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _joinSession(session),
                        icon: const FaIcon(FontAwesomeIcons.video, size: 12),
                        label: const Text('Join', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (status == 'ready')
                    const SizedBox(width: 8),
                  if (status == 'ready')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startSession(session),
                        icon: const FaIcon(FontAwesomeIcons.play, size: 12),
                        label: const Text('Start', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (status == 'in_progress')
                    const SizedBox(width: 8),
                  if (status == 'in_progress')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _endSession(session),
                        icon: const FaIcon(FontAwesomeIcons.stop, size: 12),
                        label: const Text('End', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentAvatar(Map<String, dynamic> student) {
    final initial = (student['full_name']?.toString().isNotEmpty ?? false)
        ? student['full_name'][0].toUpperCase()
        : 'S';
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.greenGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.textSecondary;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'ready':
        return 'Ready';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
