import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../services/session_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/preload_service.dart';
import '../chat/chat_conversation_screen.dart';
import 'create_session_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TeacherSessionService _sessionService = TeacherSessionService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final PreloadService _preloadService = PreloadService();
  
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _finishedSessions = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessionsFromCache();
  }

  void _loadSessionsFromCache() {
    final cached = _preloadService.sessions;
    if (cached != null) {
      setState(() {
        _upcomingSessions = cached.upcoming;
        _finishedSessions = cached.finished;
        _isLoading = false;
      });
      print('✅ Loaded sessions from cache');
      return;
    }
    
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
      
      _preloadService.cacheSessions(
        upcoming: upcoming,
        finished: finished,
      );
      
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.white,
        title: const Text(
          'End Session',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to end this session? This will mark it as completed and deduct a point from the subscription.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.greenGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'End Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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

  Future<void> _cancelSession(Map<String, dynamic> session) async {
    // Show dialog to get cancellation reason
    final TextEditingController reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.white,
        title: const Text(
          'Cancel Session',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this session? The student will be notified.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter cancellation reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Cancel Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final reason = reasonController.text.isEmpty ? 'Cancelled by teacher' : reasonController.text;
      final success = await _sessionService.cancelSession(session['id'], reason);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session cancelled successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadSessions();
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    reasonController.dispose();
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.white,
        title: const Text(
          'Delete Session',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this session? This action cannot be undone.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final isTeacherCreated = session['teacher_created'] == true;
      final success = await _sessionService.deleteSession(session['id'], isTeacherCreated);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session deleted successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadSessions();
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete session. Only teacher-created scheduled sessions can be deleted.'),
            backgroundColor: Colors.red,
          ),
        );
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
      final launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not open the meeting link');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining session: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openChatWithStudent(Map<String, dynamic> session) async {
    try {
      final student = session['student'];
      if (student == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student information not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final studentId = student['id'];
      final studentName = student['full_name'] ?? 'Student';
      final studentAvatar = student['avatar_url'];

      // Get or create conversation
      final conversation = await _chatService.getOrCreateConversation(studentId);
      
      if (conversation != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              conversationId: conversation['id'],
              recipientId: studentId,
              recipientName: studentName,
              recipientAvatar: studentAvatar,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start chat. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToCreateSession() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateSessionScreen(),
      ),
    );
    
    // If session was created successfully, reload sessions
    if (result == true) {
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateSession,
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const FaIcon(
                        FontAwesomeIcons.bars,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'MY CLASSES',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 45), // Balance the menu button
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
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        RefreshIndicator(
                          onRefresh: _loadSessions,
                          color: AppColors.primary,
                          child: _buildClassesList(_upcomingSessions, isUpcoming: true),
                        ),
                        RefreshIndicator(
                          onRefresh: _loadSessions,
                          color: AppColors.primary,
                          child: _buildClassesList(_finishedSessions, isUpcoming: false),
                        ),
                      ],
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
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
                  if (isUpcoming) ...[
                    const SizedBox(height: 16),
                    Icon(
                      Icons.arrow_downward,
                      color: AppColors.textSecondary.withOpacity(0.3),
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
    final isMakeup = session['is_makeup'] == true;
    final isTeacherCreated = session['teacher_created'] == true;

    final scheduledDate = DateTime.parse(session['scheduled_date']);
    final today = DateTime.now();
    final isToday = scheduledDate.year == today.year && 
                    scheduledDate.month == today.month && 
                    scheduledDate.day == today.day;
    
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
        border: isToday && isUpcoming
            ? Border.all(color: Colors.green.shade400, width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isToday && isUpcoming
                ? Colors.green.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isToday && isUpcoming ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today indicator (for upcoming sessions only)
          if (isToday && isUpcoming) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.today,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      startTime,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Makeup session indicator
          if (isMakeup) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    color: Colors.orange.shade700,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MAKEUP CLASS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Teacher-created indicator
          if (isTeacherCreated) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MANUALLY CREATED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholderFadeInDuration: Duration.zero,
                    memCacheWidth: 96,
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
              Stack(
                children: [
                  ClipOval(
                    child: student['avatar_url'] != null
                        ? CachedNetworkImage(
                            imageUrl: student['avatar_url'],
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholderFadeInDuration: Duration.zero,
                            memCacheWidth: 96,
                            errorWidget: (context, url, error) => _buildStudentAvatar(student),
                          )
                        : _buildStudentAvatar(student),
                  ),
                  // Online indicator
                  if (student['is_online'] == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
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
              // Chat Button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const FaIcon(
                    FontAwesomeIcons.comment,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _openChatWithStudent(session),
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
            // First row: Link, Join, Start buttons
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
                // Show Join button if meeting link is set
                if ((status == 'ready' || status == 'in_progress') &&
                    session['meeting_link'] != null && 
                    session['meeting_link'].toString().isNotEmpty) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _joinSession(session),
                      icon: const FaIcon(FontAwesomeIcons.video, size: 12, color: Colors.white),
                      label: const Text('Join', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
                // Show Start button if status is ready
                if (status == 'ready') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startSession(session),
                      icon: const FaIcon(FontAwesomeIcons.play, size: 12, color: Colors.white),
                      label: const Text('Start', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
                // Show End button if session is in progress
                if (status == 'in_progress') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _endSession(session),
                      icon: const FaIcon(FontAwesomeIcons.stop, size: 12, color: Colors.white),
                      label: const Text('End', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Second row: Cancel/Delete buttons
            if (status == 'scheduled' || status == 'ready') ...[
              const SizedBox(height: 8),
              // Show Delete for teacher-created sessions
              if (isTeacherCreated)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteSession(session),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Delete Session', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                )
              // Show Cancel for automatic sessions
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelSession(session),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('Cancel Session', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
            ],
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
      case 'missed':
        return Colors.orange;
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
      case 'missed':
        return 'Missed';
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
