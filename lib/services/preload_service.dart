import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:teacher/services/auth_service.dart';
import 'package:teacher/services/language_service.dart';
import 'package:teacher/services/chat_service.dart';
import 'package:teacher/services/session_service.dart';
import 'package:teacher/services/rating_service.dart';
import 'package:teacher/services/point_award_service.dart';

/// Service to preload and cache all app data for teachers
class PreloadService {
  final _authService = AuthService();
  final _languageService = LanguageService();
  final _chatService = ChatService();
  final _sessionService = TeacherSessionService();
  final _ratingService = RatingService();
  final _pointAwardService = PointAwardService();

  // Cached data - Basic
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>>? _teacherLanguages;
  
  // Dashboard statistics
  int? _totalStudents;
  int? _upcomingSessions;
  int? _totalSessions;
  Map<String, dynamic>? _ratingStats;
  DateTime? _statsTimestamp;

  // Cached data - Students
  List<Map<String, dynamic>>? _students;
  DateTime? _studentsTimestamp;

  // Cached data - Chat
  List<Map<String, dynamic>>? _conversations;
  List<Map<String, dynamic>>? _availableStudents;
  DateTime? _chatTimestamp;

  // Cached data - Chat Messages (keyed by conversationId)
  final Map<String, List<Map<String, dynamic>>> _messagesCache = {};

  // Cached data - Classes/Sessions
  List<Map<String, dynamic>>? _upcomingClassSessions;
  List<Map<String, dynamic>>? _finishedClassSessions;
  DateTime? _sessionsTimestamp;

  // Singleton pattern
  static final PreloadService _instance = PreloadService._internal();
  factory PreloadService() => _instance;
  PreloadService._internal();

  /// Preload all data for logged-in teacher
  Future<void> preloadData({required bool isLoggedIn, BuildContext? context}) async {
    try {
      final List<Future> tasks = [];
      
      if (isLoggedIn) {
        tasks.add(_loadTeacherData());
      }
      
      // Start image precaching in parallel
      if (context != null && context.mounted && isLoggedIn) {
        tasks.add(_precacheImages(context));
      }
      
      await Future.wait(tasks);
      print('✅ Teacher preloading completed successfully');
    } catch (e) {
      print('❌ Error during teacher preloading: $e');
    }
  }

  Future<void> _loadTeacherData() async {
    try {
      final teacherId = _authService.currentUser?.id;
      if (teacherId == null) return;

      // Load all teacher data in parallel
      final results = await Future.wait([
        _authService.getTeacherProfile(),
        _languageService.getTeacherLanguages(teacherId),
        _pointAwardService.getMyStudents(),
        _sessionService.getUpcomingSessions(),
        _sessionService.getMySessions(),
        _ratingService.getMyRatingStats(),
      ]);

      _profile = results[0] as Map<String, dynamic>?;
      _teacherLanguages = results[1] as List<Map<String, dynamic>>;
      _totalStudents = (results[2] as List).length;
      _upcomingSessions = (results[3] as List).length;
      _totalSessions = (results[4] as List).length;
      _ratingStats = results[5] as Map<String, dynamic>?;
      _statsTimestamp = DateTime.now();

      print('✅ Preloaded teacher profile and dashboard data');
    } catch (e) {
      print('❌ Failed to preload teacher data: $e');
    }
  }

  Future<void> _precacheImages(BuildContext context) async {
    if (!context.mounted) return;
    
    try {
      final List<Future> imageFutures = [];
      print('🖼️ Starting image precaching...');
      
      // Precache logo
      imageFutures.add(
        precacheImage(const AssetImage('assets/images/logo.jpg'), context)
          .then((_) => print('  ✅ Cached logo.jpg'))
          .catchError((e) => print('  ❌ Failed to precache logo.jpg: $e'))
      );

      // Precache teacher avatar
      final avatarUrl = _profile?['avatar_url'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        imageFutures.add(
          precacheImage(CachedNetworkImageProvider(avatarUrl), context)
            .catchError((e) => print('  ❌ Failed to precache avatar: $e'))
        );
      }
      
      await Future.wait(imageFutures);
      print('✅ Image precaching finished');
    } catch (e) {
      print('❌ Error precaching images: $e');
    }
  }

  // Getters for cached data
  Map<String, dynamic>? get profile => _profile;
  List<Map<String, dynamic>>? get teacherLanguages => _teacherLanguages;
  int? get totalStudents => _totalStudents;
  int? get upcomingSessions => _upcomingSessions;
  int? get totalSessions => _totalSessions;
  Map<String, dynamic>? get ratingStats => _ratingStats;

  bool get hasProfile => _profile != null;
  bool get hasStats => _statsTimestamp != null;

  // ========== STUDENTS CACHE ==========
  
  List<Map<String, dynamic>>? get students => _students;

  void cacheStudents(List<Map<String, dynamic>> students) {
    _students = students;
    _studentsTimestamp = DateTime.now();
    print('📦 Cached ${students.length} students');
  }

  void invalidateStudents() {
    _students = null;
    _studentsTimestamp = null;
    print('🗑️ Invalidated students cache');
  }

  // ========== CHAT CACHE ==========
  
  ({List<Map<String, dynamic>> conversations, List<Map<String, dynamic>> students})? get chatData {
    if (_conversations == null || _chatTimestamp == null) return null;
    return (conversations: _conversations!, students: _availableStudents ?? []);
  }

  void cacheChat({
    required List<Map<String, dynamic>> conversations,
    required List<Map<String, dynamic>> students,
  }) {
    _conversations = conversations;
    _availableStudents = students;
    _chatTimestamp = DateTime.now();
    print('📦 Cached ${conversations.length} conversations, ${students.length} students');
  }

  void invalidateChat() {
    _conversations = null;
    _availableStudents = null;
    _chatTimestamp = null;
    print('🗑️ Invalidated chat cache');
  }

  // ========== CHAT MESSAGES CACHE ==========
  
  List<Map<String, dynamic>>? getMessages(String conversationId) {
    return _messagesCache[conversationId];
  }

  void cacheMessages(String conversationId, List<Map<String, dynamic>> messages) {
    _messagesCache[conversationId] = messages;
    print('📦 Cached ${messages.length} messages for conversation $conversationId');
  }

  void addMessageToCache(String conversationId, Map<String, dynamic> message) {
    if (_messagesCache[conversationId] != null) {
      final exists = _messagesCache[conversationId]!.any((m) => m['id'] == message['id']);
      if (!exists) {
        _messagesCache[conversationId]!.add(message);
      }
    }
  }

  void invalidateMessages(String conversationId) {
    _messagesCache.remove(conversationId);
    print('🗑️ Invalidated messages cache for $conversationId');
  }

  // ========== SESSIONS CACHE ==========
  
  ({List<Map<String, dynamic>> upcoming, List<Map<String, dynamic>> finished})? get sessions {
    if (_upcomingClassSessions == null || _sessionsTimestamp == null) return null;
    return (upcoming: _upcomingClassSessions!, finished: _finishedClassSessions ?? []);
  }

  void cacheSessions({
    required List<Map<String, dynamic>> upcoming,
    required List<Map<String, dynamic>> finished,
  }) {
    _upcomingClassSessions = upcoming;
    _finishedClassSessions = finished;
    _sessionsTimestamp = DateTime.now();
    print('📦 Cached ${upcoming.length} upcoming and ${finished.length} finished sessions');
  }

  void invalidateSessions() {
    _upcomingClassSessions = null;
    _finishedClassSessions = null;
    _sessionsTimestamp = null;
    print('🗑️ Invalidated sessions cache');
  }

  /// Refresh teacher profile data
  Future<void> refreshTeacherData() async {
    try {
      final teacherId = _authService.currentUser?.id;
      if (teacherId == null) return;

      await _loadTeacherData();
      print('🔄 Teacher data refreshed');
    } catch (e) {
      print('❌ Failed to refresh teacher data: $e');
    }
  }

  /// Clear all cached data (useful for logout)
  void clearCache() {
    _profile = null;
    _teacherLanguages = null;
    _totalStudents = null;
    _upcomingSessions = null;
    _totalSessions = null;
    _ratingStats = null;
    _statsTimestamp = null;
    _students = null;
    _studentsTimestamp = null;
    _conversations = null;
    _availableStudents = null;
    _chatTimestamp = null;
    _messagesCache.clear();
    _upcomingClassSessions = null;
    _finishedClassSessions = null;
    _sessionsTimestamp = null;
    print('🧹 All teacher caches cleared');
  }
}

