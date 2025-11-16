import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:teacher/services/chat_service.dart';
import 'package:teacher/services/presence_service.dart';
import 'package:teacher/screens/chat/chat_conversation_screen.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  final _presenceService = PresenceService();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  List<Map<String, dynamic>> _availableStudents = [];
  bool _isLoading = true;
  bool _showAvailable = false;
  Timer? _statusRefreshTimer;
  
  // Track online status for each user
  final Map<String, bool> _onlineStatus = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _chatService.subscribeToConversations();
    
    // Listen to conversation updates
    _chatService.onConversationUpdate.listen((update) {
      _loadData();
    });
    
    // Search listener
    _searchController.addListener(_filterConversations);
    
    // Periodically refresh online status (every 30 seconds)
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshOnlineStatus();
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    _searchController.dispose();
    _chatService.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conv) {
          final student = conv['student'] as Map<String, dynamic>?;
          final name = student?['full_name'] ?? '';
          final lastMessage = conv['last_message'] ?? '';
          return name.toLowerCase().contains(query) || 
                 lastMessage.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    final conversations = await _chatService.getConversations();
    final students = await _chatService.getAvailableStudents();
    
    if (mounted) {
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
        _availableStudents = students;
        _isLoading = false;
      });
      
      // Subscribe to online status for all conversation participants
      for (var conversation in conversations) {
        final student = conversation['student'] as Map<String, dynamic>?;
        if (student != null && student['id'] != null) {
          _subscribeToUserStatus(student['id'], 'student');
        }
      }
      
      // Subscribe to online status for available students
      for (var student in students) {
        final studentId = student['id'];
        if (studentId != null) {
          _subscribeToUserStatus(studentId, 'student');
        }
      }
    }
  }
  
  void _subscribeToUserStatus(String userId, String userType) {
    final key = '$userId-$userType';
    if (_onlineStatus.containsKey(key)) return; // Already subscribed
    
    _presenceService.subscribeToUserStatus(userId, userType).listen((isOnline) {
      if (mounted) {
        setState(() {
          _onlineStatus[key] = isOnline;
        });
      }
    });
  }
  
  /// Refresh online status for all tracked users
  Future<void> _refreshOnlineStatus() async {
    if (!mounted) return;
    
    for (var key in _onlineStatus.keys.toList()) {
      final parts = key.split('-');
      if (parts.length != 2) continue;
      
      final userId = parts[0];
      final userType = parts[1];
      
      try {
        final isOnline = await _presenceService.isUserOnline(userId, userType);
        if (mounted) {
          setState(() {
            _onlineStatus[key] = isOnline;
          });
        }
      } catch (e) {
        print('Error refreshing status for $key: $e');
      }
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays == 0) {
        return DateFormat.jm().format(date);
      } else if (difference.inDays == 1) {
        return '1d ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat.MMMd().format(date);
      }
    } catch (e) {
      return '';
    }
  }

  // Get online users from conversations
  List<Map<String, dynamic>> get _onlineUsers {
    return _conversations.where((conv) {
      final student = conv['student'] as Map<String, dynamic>?;
      if (student == null || student['id'] == null) return false;
      final key = '${student['id']}-student';
      return _onlineStatus[key] == true;
    }).map((conv) {
      final student = conv['student'] as Map<String, dynamic>?;
      return {
        'name': (student?['full_name'] ?? 'Student').split(' ')[0], // First name only
        'image': student?['avatar_url'] ?? '',
      };
    }).toList();
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
                        'MESSAGES',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
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
                      icon: FaIcon(
                        _showAvailable ? FontAwesomeIcons.message : FontAwesomeIcons.userPlus,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _showAvailable = !_showAvailable;
                        });
                      },
                      tooltip: _showAvailable ? 'Show Conversations' : 'Start New Chat',
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          // Search Bar - Bean Shaped
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.magnifyingGlass,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: const InputDecoration(
                                        hintText: 'Search messages...',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 15,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Online Users Horizontal List
                          if (_onlineUsers.isNotEmpty && !_showAvailable)
                            SizedBox(
                              height: 90,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _onlineUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _onlineUsers[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            ClipOval(
                                              child: user['image'] != null && user['image'].toString().isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: user['image'],
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (_, __, ___) => Container(
                                                        width: 60,
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                          gradient: AppColors.greenGradient,
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            user['name'][0].toUpperCase(),
                                                            style: const TextStyle(
                                                              fontSize: 24,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppColors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      width: 60,
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        gradient: AppColors.greenGradient,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          user['name'][0].toUpperCase(),
                                                          style: const TextStyle(
                                                            fontSize: 24,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                            // Online indicator
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4CAF50),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppColors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          user['name'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Chat List or Available Students
                          _showAvailable
                              ? _buildAvailableStudentsList()
                              : _buildConversationsList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_filteredConversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.message,
                  size: 40,
                  color: AppColors.grey.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _searchController.text.isNotEmpty ? 'No results found' : 'No messages yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty 
                    ? 'Try searching with different keywords'
                    : 'Start chatting with your students',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchController.text.isEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAvailable = true;
                    });
                  },
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                  label: const Text('Start New Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        return _buildChatItem(_filteredConversations[index]);
      },
    );
  }

  Widget _buildChatItem(Map<String, dynamic> conversation) {
    final student = conversation['student'] as Map<String, dynamic>?;
    
    // Skip if student data is null
    if (student == null) {
      return const SizedBox.shrink();
    }
    
    final unreadCount = conversation['teacher_unread_count'] ?? 0;
    final lastMessage = conversation['last_message'] ?? '';
    final lastMessageAt = conversation['last_message_at'];
    final name = student['full_name'] ?? 'Student';
    final avatarUrl = student['avatar_url'];
    final studentId = student['id'];

    final userKey = '$studentId-student';
    final isOnline = _onlineStatus[userKey] ?? false;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              conversationId: conversation['id'],
              recipientId: studentId,
              recipientName: name,
              recipientAvatar: avatarUrl,
            ),
          ),
        );
        _loadData(); // Refresh after returning
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFEEEEEE),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Profile Image with Online Status
            Stack(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Message Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF999999),
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Time and Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(lastMessageAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableStudentsList() {
    if (_availableStudents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.userGroup,
                  size: 40,
                  color: AppColors.grey.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No students available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Wait for students to subscribe to your courses',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _availableStudents.length,
      itemBuilder: (context, index) {
        final student = _availableStudents[index];
        final unreadCount = student['unread_count'] ?? 0;
        final userKey = '${student['id']}-student';
        final isOnline = _onlineStatus[userKey] ?? false;
        final name = student['full_name'] ?? 'Student';
        final avatarUrl = student['avatar_url'];

        return GestureDetector(
          onTap: () async {
            // Create or get conversation
            final conversation = await _chatService.getOrCreateConversation(student['id']);
            
            if (conversation != null && mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatConversationScreen(
                    conversationId: conversation['id'],
                    recipientId: student['id'],
                    recipientName: name,
                    recipientAvatar: avatarUrl,
                  ),
                ),
              );
              setState(() {
                _showAvailable = false;
              });
              _loadData();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to start chat. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Profile Image with Online Status
                Stack(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Center(
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student['email'] ?? 'Student',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Badge and Arrow
                Row(
                  children: [
                    if (unreadCount > 0) ...[
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const FaIcon(
                      FontAwesomeIcons.chevronRight,
                      size: 14,
                      color: Color(0xFF999999),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
