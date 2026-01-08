import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:teacher/services/chat_service.dart';
import 'package:teacher/services/presence_service.dart';
import 'package:teacher/services/preload_service.dart';
import 'package:teacher/screens/chat/chat_conversation_screen.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _chatService = ChatService();
  final _presenceService = PresenceService();
  final _preloadService = PreloadService();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  List<Map<String, dynamic>> _availableStudents = [];
  bool _isLoading = false;
  bool _showAvailable = false;
  Timer? _statusRefreshTimer;
  
  // Track online status for each user
  final Map<String, bool> _onlineStatus = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDataFromCache();
    _chatService.subscribeToConversations();
    
    // Listen to conversation updates
    _chatService.onConversationUpdate.listen((update) async {
      if (mounted) {
        // Update individual conversation instead of full reload
        final conversationId = update['id'];
        final index = _conversations.indexWhere((c) => c['id'] == conversationId);
        
        if (index != -1) {
          // Update existing conversation
          setState(() {
            _conversations[index] = {..._conversations[index], ...update};
            // Re-sort conversations by last_message_at (newest first)
            _conversations.sort((a, b) {
              final aTime = a['last_message_at'] as String?;
              final bTime = b['last_message_at'] as String?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });
            _filteredConversations = _conversations;
          });
          
          // Update cache
          _preloadService.cacheChat(
            conversations: _conversations,
            students: _availableStudents,
          );
        } else {
          // New conversation or undeleted conversation - fetch full data
          try {
            final userId = _chatService.supabase.auth.currentUser?.id;
            if (userId != null) {
              // Fetch the full conversation with joined data
              final fullConversation = await _chatService.supabase
                  .from('chat_conversations')
                  .select('''
                    *,
                    student:student_id (
                      id,
                      full_name,
                      avatar_url,
                      email
                    )
                  ''')
                  .eq('id', conversationId)
                  .maybeSingle();
              
              if (fullConversation != null && 
                  fullConversation['deleted_by_teacher'] == false) {
                // Add to list if not deleted
                setState(() {
                  _conversations.insert(0, fullConversation);
                  _filteredConversations = _conversations;
                });
                
                // Update cache
                _preloadService.cacheChat(
                  conversations: _conversations,
                  students: _availableStudents,
                );
                
                // Subscribe to status of the new student
                final student = fullConversation['student'] as Map<String, dynamic>?;
                if (student != null && student['id'] != null) {
                  _subscribeToUserStatus(student['id'], 'student');
                }
              }
            }
          } catch (e) {
            print('Error fetching full conversation: $e');
          }
        }
      }
    });
    
    // Search listener
    _searchController.addListener(_filterConversations);
    
    // Periodically refresh online status (every 30 seconds)
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshOnlineStatus();
    });
  }

  void _loadDataFromCache() {
    final cached = _preloadService.chatData;
    if (cached != null) {
      setState(() {
        _conversations = cached.conversations;
        _filteredConversations = cached.conversations;
        _availableStudents = cached.students;
        _isLoading = false;
      });
      print('✅ Loaded chat data from cache');
      _subscribeToStatuses();
      return;
    }
    
    _loadData(forceRefresh: false);
  }

  void _subscribeToStatuses() {
    for (var conversation in _conversations) {
      final student = conversation['student'] as Map<String, dynamic>?;
      if (student != null && student['id'] != null) {
        _subscribeToUserStatus(student['id'], 'student');
      }
    }
    
    for (var student in _availableStudents) {
      final studentId = student['id'];
      if (studentId != null) {
        _subscribeToUserStatus(studentId, 'student');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusRefreshTimer?.cancel();
    _searchController.dispose();
    _chatService.dispose();
    _presenceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh chat conversations
      print('🔄 Chat screen: App resumed - refreshing data');
      _loadData(forceRefresh: false);
    }
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

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (forceRefresh && mounted) {
      setState(() => _isLoading = true);
    }
    
    // Parallelize queries
    final results = await Future.wait([
      _chatService.getConversations(),
      _chatService.getAvailableStudents(),
    ]);
    
    final conversations = results[0] as List<Map<String, dynamic>>;
    final students = results[1] as List<Map<String, dynamic>>;
    
    // Cache the data
    _preloadService.cacheChat(
      conversations: conversations,
      students: students,
    );
    
    if (mounted) {
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
        _availableStudents = students;
        _isLoading = false;
      });
      
      _subscribeToStatuses();
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
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return AppLocalizations.of(context).justNow;
      } else if (difference.inMinutes < 60) {
        return AppLocalizations.of(context).minutesAgo(difference.inMinutes);
      } else if (difference.inDays == 0 && date.day == now.day) {
        return DateFormat.jm().format(date);
      } else if (difference.inDays == 1 || (difference.inDays == 0 && date.day != now.day)) {
        return AppLocalizations.of(context).oneDayAgo;
      } else if (difference.inDays < 7) {
        return AppLocalizations.of(context).daysAgo(difference.inDays);
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
        'name': (student?['full_name'] ?? AppLocalizations.of(context).studentPlaceholder).split(' ')[0], // First name only
        'image': student?['avatar_url'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
                  Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).messagesTitle,
                        style: const TextStyle(
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
                      tooltip: _showAvailable ? AppLocalizations.of(context).showConversations : AppLocalizations.of(context).startNewChat,
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
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context).searchMessages,
                                        hintStyle: const TextStyle(
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
                                                      fadeInDuration: Duration.zero,
                                                      fadeOutDuration: Duration.zero,
                                                      placeholderFadeInDuration: Duration.zero,
                                                      memCacheWidth: 180,
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
                _searchController.text.isNotEmpty ? AppLocalizations.of(context).noResultsFound : AppLocalizations.of(context).noMessagesYet,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty 
                    ? AppLocalizations.of(context).tryDifferentKeywords
                    : AppLocalizations.of(context).startConversationWithStudents,
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
                  label: Text(AppLocalizations.of(context).startNewChat),
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

  void _showChatOptions(String conversationId, String recipientName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle at top
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.trashCan,
                color: Colors.red,
                size: 20,
              ),
              title: Text(
                AppLocalizations.of(context).deleteChat,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteChatConfirmation(conversationId, recipientName);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showDeleteChatConfirmation(String conversationId, String recipientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          AppLocalizations.of(context).deleteChatQuestion,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context).deleteChatConfirmation(recipientName),
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChat(conversationId);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).delete,
              style: TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String conversationId) async {
    try {
      await _chatService.supabase
          .from('chat_conversations')
          .update({
            'deleted_by_teacher': true,
            'teacher_deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      // Remove from local state
      setState(() {
        _conversations.removeWhere((conv) => conv['id'] == conversationId);
        _filteredConversations.removeWhere((conv) => conv['id'] == conversationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).chatDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedToDeleteChat),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final name = student['full_name'] ?? AppLocalizations.of(context).studentPlaceholder;
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
              previewMessage: lastMessage,
              previewTime: lastMessageAt,
              isUnread: unreadCount > 0,
            ),
          ),
        );
        // Cache is still valid - real-time listener handles updates
      },
      onLongPress: () => _showChatOptions(conversation['id'], name),
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
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholderFadeInDuration: Duration.zero,
                            memCacheWidth: 165,
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
                  _getLastMessagePreview(conversation),
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
                AppLocalizations.of(context).noStudentsAvailable,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).waitForStudentsToSubscribe,
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
        final name = student['full_name'] ?? AppLocalizations.of(context).studentPlaceholder;
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
              _preloadService.invalidateChat();
              _loadData(forceRefresh: true);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).unableToStartChat),
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
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholderFadeInDuration: Duration.zero,
                                memCacheWidth: 165,
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
                        student['email'] ?? AppLocalizations.of(context).studentPlaceholder,
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

  String _getLastMessagePreview(Map<String, dynamic> conversation) {
    final lastMessage = conversation['last_message'] ?? '';
    final hasAttachment = conversation['has_attachment'] == true;
    final attachmentType = conversation['last_attachment_type'];
    
    // If there's an attachment but no text, show attachment type
    if (hasAttachment && lastMessage.isEmpty) {
      switch (attachmentType) {
        case 'image':
          return AppLocalizations.of(context).imageAttachment;
        case 'voice':
          return AppLocalizations.of(context).voiceMessage;
        case 'file':
          return AppLocalizations.of(context).fileAttachment;
        default:
          return AppLocalizations.of(context).attachmentGeneric;
      }
    }
    
    // If there's text, return it (even if there's also an attachment)
    if (lastMessage.isNotEmpty) {
      return lastMessage;
    }
    
    // No message and no attachment
    return AppLocalizations.of(context).startChatting;
  }
  
  bool _isImageType(String? fileType) {
    if (fileType == null) return false;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileType.toLowerCase());
  }
}
