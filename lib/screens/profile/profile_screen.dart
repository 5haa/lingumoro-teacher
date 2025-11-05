import 'package:flutter/material.dart';
import 'package:teacher/services/auth_service.dart';
import 'package:teacher/services/rating_service.dart';
import 'package:teacher/screens/auth/login_screen.dart';
import 'package:teacher/screens/profile/edit_profile_screen.dart';
import 'package:teacher/widgets/rating_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _ratingService = RatingService();
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _ratingStats;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getTeacherProfile();
      final ratingStats = await _ratingService.getMyRatingStats();
      final reviews = await _ratingService.getMyRatings();
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _ratingStats = ratingStats;
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _showEditMeetingLinkDialog() async {
    final controller = TextEditingController(text: _profile?['meeting_link'] ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Default Meeting Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This link will be automatically used for all your upcoming sessions.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Meeting Link',
                hintText: 'https://meet.google.com/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Students will be able to join sessions using this link',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _authService.updateMeetingLink(result);
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting link updated successfully! All upcoming sessions will use this link.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update meeting link: $e')),
          );
        }
      }
    }
  }

  void _showAllReviewsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Reviews',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RatingReviewCard(review: _reviews[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile header
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
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              _profile?['full_name']?[0]?.toUpperCase() ?? 'T',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profile?['full_name'] ?? 'Teacher',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_profile?['specialization'] != null) ...[
                            Text(
                              _profile!['specialization'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            _profile?['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          if (_profile?['phone'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _profile!['phone'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                          // Rating badge in header
                          if (_ratingStats != null && ((_ratingStats!['total_ratings'] as int?) ?? 0) > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: RatingDisplay(
                                averageRating: (_ratingStats!['average_rating'] as num?)?.toDouble() ?? 0.0,
                                totalRatings: (_ratingStats!['total_ratings'] as int?) ?? 0,
                                compact: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Profile details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ratings Section
                          if (_ratingStats != null && ((_ratingStats!['total_ratings'] as int?) ?? 0) > 0) ...[
                            RatingDisplay(
                              averageRating: (_ratingStats!['average_rating'] as num?)?.toDouble() ?? 0.0,
                              totalRatings: (_ratingStats!['total_ratings'] as int?) ?? 0,
                              starCounts: {
                                5: (_ratingStats!['five_star_count'] as int?) ?? 0,
                                4: (_ratingStats!['four_star_count'] as int?) ?? 0,
                                3: (_ratingStats!['three_star_count'] as int?) ?? 0,
                                2: (_ratingStats!['two_star_count'] as int?) ?? 0,
                                1: (_ratingStats!['one_star_count'] as int?) ?? 0,
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Recent Reviews Section
                          if (_reviews.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Reviews',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Show all reviews dialog
                                    _showAllReviewsDialog();
                                  },
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...(_reviews.take(3).map((review) => 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: RatingReviewCard(review: review),
                              )
                            )),
                            const SizedBox(height: 24),
                          ],
                          
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildInfoCard(
                            'Full Name',
                            _profile?['full_name'] ?? 'N/A',
                            Icons.person,
                          ),
                          const SizedBox(height: 12),

                          if (_profile?['specialization'] != null) ...[
                            _buildInfoCard(
                              'Specialization',
                              _profile!['specialization'],
                              Icons.school,
                            ),
                            const SizedBox(height: 12),
                          ],

                          _buildInfoCard(
                            'Email',
                            _profile?['email'] ?? 'N/A',
                            Icons.email,
                          ),
                          const SizedBox(height: 12),

                          _buildInfoCard(
                            'Phone',
                            _profile?['phone'] ?? 'N/A',
                            Icons.phone,
                          ),
                          const SizedBox(height: 12),

                          _buildInfoCard(
                            'Member Since',
                            _profile?['created_at'] != null
                                ? _formatDate(_profile!['created_at'])
                                : 'N/A',
                            Icons.calendar_today,
                          ),
                          const SizedBox(height: 12),

                          // Meeting Link Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.teal.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.video_call, color: Colors.teal, size: 24),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Default Meeting Link',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        color: Colors.teal,
                                        onPressed: _showEditMeetingLinkDialog,
                                        tooltip: 'Edit Meeting Link',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _profile?['meeting_link'] != null && 
                                    _profile!['meeting_link'].toString().isNotEmpty
                                        ? _profile!['meeting_link']
                                        : 'Not set - Click edit to add your meeting link',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _profile?['meeting_link'] != null && 
                                             _profile!['meeting_link'].toString().isNotEmpty
                                          ? Colors.grey[800]
                                          : Colors.grey[600],
                                      fontStyle: _profile?['meeting_link'] == null ||
                                                 _profile!['meeting_link'].toString().isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_profile?['meeting_link'] == null ||
                                      _profile!['meeting_link'].toString().isEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        border: Border.all(color: Colors.orange.shade200),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Set your meeting link so students can join your sessions',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Settings section
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildActionButton(
                            'Edit Profile',
                            Icons.edit,
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(profile: _profile!),
                                ),
                              );
                              // Reload profile if updated
                              if (result == true) {
                                _loadProfile();
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildActionButton(
                            'My Courses',
                            Icons.book,
                            () {
                              // TODO: Implement courses management
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildActionButton(
                            'Notifications',
                            Icons.notifications,
                            () {
                              // TODO: Implement notifications settings
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildActionButton(
                            'Privacy & Security',
                            Icons.security,
                            () {
                              // TODO: Implement privacy settings
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildActionButton(
                            'Help & Support',
                            Icons.help,
                            () {
                              // TODO: Implement help
                            },
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

