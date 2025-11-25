import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/point_award_service.dart';
import '../../services/session_service.dart';
import '../../services/rating_service.dart';
import '../../services/preload_service.dart';
import '../../l10n/app_localizations.dart';
import '../schedule/schedule_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  
  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final _authService = AuthService();
  final _languageService = LanguageService();
  final _pointAwardService = PointAwardService();
  final _sessionService = TeacherSessionService();
  final _ratingService = RatingService();
  final _preloadService = PreloadService();
  
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _teacherLanguages = [];
  
  // Dashboard statistics
  int _totalStudents = 0;
  int _upcomingSessions = 0;
  int _totalSessions = 0;
  Map<String, dynamic>? _ratingStats;
  
  bool _isLoading = false;
  bool _isLoadingLanguages = false;

  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _loadDataFromCache();
  }

  void _loadDataFromCache() {
    // Try to load from cache first
    if (_preloadService.hasProfile) {
      _profile = _preloadService.profile;
      _teacherLanguages = _preloadService.teacherLanguages ?? [];
      if (_preloadService.hasStats) {
        _totalStudents = _preloadService.totalStudents ?? 0;
        _upcomingSessions = _preloadService.upcomingSessions ?? 0;
        _totalSessions = _preloadService.totalSessions ?? 0;
        _ratingStats = _preloadService.ratingStats;
      }
      setState(() {
        _isLoading = false;
      });
      print('✅ Loaded teacher dashboard from cache');
      return;
    }
    
    // No cache, load from API
    _loadAllData();
  }
  
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load profile
      final profile = await _authService.getTeacherProfile();
      
      if (profile != null) {
        // Load all data in parallel
        await Future.wait([
          _loadTeacherLanguages(profile['id']),
          _loadDashboardStats(profile['id']),
        ]);
      }
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadTeacherLanguages(String teacherId) async {
    setState(() => _isLoadingLanguages = true);
    try {
      final languages = await _languageService.getTeacherLanguages(teacherId);
      if (mounted) {
        setState(() {
          _teacherLanguages = languages;
          _isLoadingLanguages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLanguages = false);
      }
    }
  }
  
  Future<void> _loadDashboardStats(String teacherId) async {
    try {
      // Load statistics in parallel
      final results = await Future.wait([
        _pointAwardService.getMyStudents(),
        _sessionService.getUpcomingSessions(),
        _sessionService.getMySessions(),
        _ratingService.getMyRatingStats(),
      ]);
      
      if (mounted) {
        setState(() {
          _totalStudents = (results[0] as List).length;
          _upcomingSessions = (results[1] as List).length;
          _totalSessions = (results[2] as List).length;
          _ratingStats = results[3] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      print('Error loading dashboard stats: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),
            
            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAllData,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            
                            // Dashboard Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).dashboard,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Statistics Cards
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          AppLocalizations.of(context).students,
                                          '$_totalStudents',
                                          FontAwesomeIcons.userGroup,
                                          AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: _buildStatCard(
                                          AppLocalizations.of(context).upcomingSessions,
                                          '$_upcomingSessions',
                                          FontAwesomeIcons.calendar,
                                          AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 10),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          AppLocalizations.of(context).totalSessions,
                                          '$_totalSessions',
                                          FontAwesomeIcons.video,
                                          AppColors.primaryLight,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildStatCard(
                                          AppLocalizations.of(context).rating,
                                          _ratingStats != null && (_ratingStats!['total_ratings'] ?? 0) > 0
                                              ? '${(_ratingStats!['average_rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}'
                                              : 'N/A',
                                          FontAwesomeIcons.star,
                                          Colors.amber.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Languages I Teach Section
                                  Text(
                                    AppLocalizations.of(context).languagesITeach,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  _isLoadingLanguages
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: 16.0),
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                            ),
                                          ),
                                        )
                                      : _teacherLanguages.isEmpty
                                          ? Center(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      FontAwesomeIcons.language,
                                                      size: 36,
                                                      color: AppColors.grey.withOpacity(0.5),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      AppLocalizations.of(context).noLanguagesAssigned,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: AppColors.textSecondary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : SizedBox(
                                              height: 80,
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: _teacherLanguages.length,
                                                itemBuilder: (context, index) {
                                                  final langData = _teacherLanguages[index];
                                                  final lang = langData['language_courses'];
                                                  if (lang == null) return const SizedBox.shrink();
                                                  
                                                  return _buildLanguageCard(
                                                    lang['name'] ?? '',
                                                    lang['flag_url'],
                                                  );
                                                },
                                              ),
                                            ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Quick Actions Section
                                  Text(
                                    AppLocalizations.of(context).quickActions,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Single row with all 4 quick actions
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildActionCard(
                                          AppLocalizations.of(context).schedule,
                                          FontAwesomeIcons.calendarDays,
                                          AppColors.primary,
                                          () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const ScheduleScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildActionCard(
                                          AppLocalizations.of(context).sessions,
                                          FontAwesomeIcons.video,
                                          AppColors.primaryDark,
                                          () {
                                            // Switch to Classes tab (index 1)
                                            widget.onTabChange?.call(1);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildActionCard(
                                          AppLocalizations.of(context).students,
                                          FontAwesomeIcons.userGroup,
                                          AppColors.primaryLight,
                                          () {
                                            // Switch to Students tab (index 2)
                                            widget.onTabChange?.call(2);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildActionCard(
                                          AppLocalizations.of(context).chat,
                                          FontAwesomeIcons.message,
                                          Colors.blue.shade400,
                                          () {
                                            // Switch to Chat tab (index 3)
                                            widget.onTabChange?.call(3);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Menu Icon
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
          
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context).appName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          // Notification Icon
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const FaIcon(FontAwesomeIcons.bell, size: 20),
              color: AppColors.textPrimary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvatarInitial() {
    final initial = (_profile?['full_name']?.toString().isNotEmpty ?? false)
        ? _profile!['full_name'][0].toUpperCase()
        : 'T';
    
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.greenGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                ),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageCard(String name, String? flagUrl) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: flagUrl != null
                ? CachedNetworkImage(
                    imageUrl: flagUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 36,
                      height: 36,
                      color: AppColors.lightGrey,
                      child: Icon(
                        Icons.language,
                        size: 18,
                        color: AppColors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.language,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),
                  )
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.language,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
