import 'package:flutter/material.dart';
import 'package:teacher/services/auth_service.dart';
import 'package:teacher/services/language_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _languageService = LanguageService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _teacherLanguages = [];
  bool _isLoading = true;
  bool _isLoadingLanguages = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getTeacherProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
      // Load teacher's languages
      if (profile != null) {
        _loadTeacherLanguages(profile['id']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTeacherLanguages(String teacherId) async {
    setState(() => _isLoadingLanguages = true);
    try {
      final languages = await _languageService.getTeacherLanguages(teacherId);
      setState(() {
        _teacherLanguages = languages;
        _isLoadingLanguages = false;
      });
    } catch (e) {
      setState(() => _isLoadingLanguages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lingumoro Teacher'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Welcome banner
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.teal.shade400,
                            Colors.teal.shade800,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _profile?['full_name'] ?? 'Teacher',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_profile?['specialization'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _profile!['specialization'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                          // Display languages taught
                          if (_teacherLanguages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _teacherLanguages.map((langData) {
                                final lang = langData['language_courses'];
                                if (lang == null) return const SizedBox.shrink();
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (lang['flag_url'] != null)
                                        Image.network(
                                          lang['flag_url'],
                                          width: 20,
                                          height: 15,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(
                                            Icons.language,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        lang['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Dashboard cards
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick stats
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            children: [
                              _buildStatCard(
                                'My Courses',
                                '0',
                                Icons.book,
                                Colors.blue,
                              ),
                              _buildStatCard(
                                'Students',
                                '0',
                                Icons.people,
                                Colors.green,
                              ),
                              _buildStatCard(
                                'Assignments',
                                '0',
                                Icons.assignment,
                                Colors.orange,
                              ),
                              _buildStatCard(
                                'Reviews',
                                '0',
                                Icons.star,
                                Colors.amber,
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Languages I Teach Section
                          const Text(
                            'Languages I Teach',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _isLoadingLanguages
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _teacherLanguages.isEmpty
                                  ? Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.language,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'No languages assigned yet',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Contact admin to get assigned to language courses',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[500],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 1.5,
                                      ),
                                      itemCount: _teacherLanguages.length,
                                      itemBuilder: (context, index) {
                                        final langData = _teacherLanguages[index];
                                        final lang = langData['language_courses'];
                                        if (lang == null) return const SizedBox.shrink();
                                        
                                        return Card(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.teal.shade400,
                                                  Colors.teal.shade600,
                                                ],
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  // Flag
                                                  if (lang['flag_url'] != null)
                                                    Container(
                                                      width: 50,
                                                      height: 35,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.2),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.network(
                                                          lang['flag_url'],
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) =>
                                                              Container(
                                                            color: Colors.white,
                                                            child: const Icon(
                                                              Icons.language,
                                                              color: Colors.teal,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    const Icon(
                                                      Icons.language,
                                                      size: 40,
                                                      color: Colors.white,
                                                    ),
                                                  const SizedBox(height: 12),
                                                  // Language name
                                                  Text(
                                                    lang['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  // Proficiency level
                                                  if (langData['proficiency_level'] != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        langData['proficiency_level'],
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                          const SizedBox(height: 32),

                          // Quick actions
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildActionButton(
                            'My Schedule',
                            Icons.calendar_today,
                            () {
                              Navigator.pushNamed(context, '/schedule');
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'My Sessions',
                            Icons.video_library,
                            () {
                              Navigator.pushNamed(context, '/sessions');
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'My Students',
                            Icons.people,
                            () {},
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Create Course',
                            Icons.add_circle,
                            () {},
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Messages',
                            Icons.message,
                            () {},
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Analytics',
                            Icons.bar_chart,
                            () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.7),
              color,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

