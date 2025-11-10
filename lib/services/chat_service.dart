import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatService {
  final _supabase = Supabase.instance.client;
  
  // Public getter for supabase client
  SupabaseClient get supabase => _supabase;
  
  // Realtime subscriptions
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationsChannel;
  RealtimeChannel? _typingChannel;
  
  // Stream controllers
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdate => _conversationUpdateController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;

  /// Get or create conversation with a student
  Future<Map<String, dynamic>?> getOrCreateConversation(String studentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if teacher has active subscription with this student
      final subscription = await _supabase
          .from('student_subscriptions')
          .select()
          .eq('student_id', studentId)
          .eq('teacher_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (subscription == null) {
        throw Exception('No active subscription found with this student');
      }

      // Check if conversation exists
      var conversation = await _supabase
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
          .eq('student_id', studentId)
          .eq('teacher_id', userId)
          .maybeSingle();

      // Create conversation if it doesn't exist
      if (conversation == null) {
        final newConversation = await _supabase
            .from('chat_conversations')
            .insert({
              'student_id': studentId,
              'teacher_id': userId,
            })
            .select('''
              *,
              student:student_id (
                id,
                full_name,
                avatar_url,
                email
              )
            ''')
            .single();
        
        conversation = newConversation;
      }

      return conversation;
    } catch (e) {
      print('Error getting/creating conversation: $e');
      return null;
    }
  }

  /// Get all conversations for current teacher
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final conversations = await _supabase
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
          .eq('teacher_id', userId)
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(conversations);
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  /// Get students that teacher can chat with (has active subscription)
  Future<List<Map<String, dynamic>>> getAvailableStudents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get all active subscriptions
      final subscriptions = await _supabase
          .from('student_subscriptions')
          .select('''
            student_id,
            student:student_id (
              id,
              full_name,
              avatar_url,
              email
            )
          ''')
          .eq('teacher_id', userId)
          .eq('status', 'active');

      // Get existing conversations
      final conversations = await _supabase
          .from('chat_conversations')
          .select('student_id, teacher_unread_count')
          .eq('teacher_id', userId);

      final conversationMap = {
        for (var conv in conversations)
          conv['student_id']: conv['teacher_unread_count'] ?? 0
      };

      // Combine student data with unread counts
      final students = subscriptions
          .where((sub) => sub['student'] != null)
          .map((sub) {
        final student = sub['student'] as Map<String, dynamic>;
        return {
          ...student,
          'unread_count': conversationMap[student['id']] ?? 0,
        };
      }).toList();

      return students;
    } catch (e) {
      print('Error fetching available students: $e');
      return [];
    }
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    try {
      final messages = await _supabase
          .from('chat_messages')
          .select('''
            *,
            attachments:chat_attachments (*)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(messages).reversed.toList();
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  /// Send a text message
  Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String messageText,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final message = await _supabase
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'sender_type': 'teacher',
            'message_text': messageText,
            'has_attachment': false,
          })
          .select('''
            *,
            attachments:chat_attachments (*)
          ''')
          .single();

      return message;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Send a message with attachment
  Future<Map<String, dynamic>?> sendMessageWithAttachment({
    required String conversationId,
    required String messageText,
    required File file,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Upload file to storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath = '$userId/$fileName';
      
      await _supabase.storage
          .from('chat-attachments')
          .upload(filePath, file);

      final fileUrl = _supabase.storage
          .from('chat-attachments')
          .getPublicUrl(filePath);

      // Create message
      final message = await _supabase
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'sender_type': 'teacher',
            'message_text': messageText,
            'has_attachment': true,
          })
          .select()
          .single();

      // Create attachment record
      await _supabase
          .from('chat_attachments')
          .insert({
            'message_id': message['id'],
            'file_name': path.basename(file.path),
            'file_url': fileUrl,
            'file_type': path.extension(file.path).replaceAll('.', ''),
            'file_size': await file.length(),
          });

      // Fetch complete message with attachments
      final completeMessage = await _supabase
          .from('chat_messages')
          .select('''
            *,
            attachments:chat_attachments (*)
          ''')
          .eq('id', message['id'])
          .single();

      return completeMessage;
    } catch (e) {
      print('Error sending message with attachment: $e');
      return null;
    }
  }

  /// Pick and upload file
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Send voice message
  Future<Map<String, dynamic>?> sendVoiceMessage({
    required String conversationId,
    required File audioFile,
    required int durationSeconds,
    String? messageText,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Upload audio file to storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_voice.m4a';
      final filePath = '$userId/$fileName';
      
      await _supabase.storage
          .from('chat-attachments')
          .upload(filePath, audioFile);

      final fileUrl = _supabase.storage
          .from('chat-attachments')
          .getPublicUrl(filePath);

      // Create message
      final message = await _supabase
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'sender_type': 'teacher',
            'message_text': messageText ?? '',
            'has_attachment': true,
          })
          .select()
          .single();

      // Create voice attachment record
      await _supabase
          .from('chat_attachments')
          .insert({
            'message_id': message['id'],
            'file_name': 'Voice Message',
            'file_url': fileUrl,
            'file_type': 'm4a',
            'file_size': await audioFile.length(),
            'attachment_type': 'voice',
            'duration_seconds': durationSeconds,
          });

      // Fetch complete message with attachments
      final completeMessage = await _supabase
          .from('chat_messages')
          .select('''
            *,
            attachments:chat_attachments (*)
          ''')
          .eq('id', message['id'])
          .single();

      return completeMessage;
    } catch (e) {
      print('Error sending voice message: $e');
      return null;
    }
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Start recording audio
  Future<AudioRecorder?> startRecording() async {
    try {
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      final recorder = AudioRecorder();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(const RecordConfig(), path: filePath);
      return recorder;
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  /// Stop recording and get file
  Future<({File? file, int duration})?> stopRecording(AudioRecorder recorder, DateTime startTime) async {
    try {
      final path = await recorder.stop();
      final duration = DateTime.now().difference(startTime).inSeconds;
      
      if (path != null) {
        return (file: File(path), duration: duration);
      }
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  /// Cancel recording
  Future<void> cancelRecording(AudioRecorder recorder) async {
    try {
      await recorder.cancel();
    } catch (e) {
      print('Error cancelling recording: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('mark_messages_as_read', params: {
        'p_conversation_id': conversationId,
        'p_user_id': userId,
      });

      await _supabase.rpc('reset_unread_count', params: {
        'p_conversation_id': conversationId,
        'p_user_id': userId,
        'p_user_type': 'teacher',
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Update typing indicator
  Future<void> updateTypingIndicator(String conversationId, bool isTyping) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('typing_indicators')
          .upsert({
            'conversation_id': conversationId,
            'user_id': userId,
            'user_type': 'teacher',
            'is_typing': isTyping,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'conversation_id,user_id');
    } catch (e) {
      print('Error updating typing indicator: $e');
    }
  }

  /// Subscribe to realtime messages for a conversation
  void subscribeToMessages(String conversationId) {
    _messagesChannel?.unsubscribe();
    
    _messagesChannel = _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) async {
            // Fetch complete message with attachments
            final message = await _supabase
                .from('chat_messages')
                .select('''
                  *,
                  attachments:chat_attachments (*)
                ''')
                .eq('id', payload.newRecord['id'])
                .single();
            
            _messageController.add(message);
          },
        )
        .subscribe();
  }

  /// Subscribe to realtime conversation updates
  void subscribeToConversations() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _conversationsChannel?.unsubscribe();
    
    _conversationsChannel = _supabase
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'teacher_id',
            value: userId,
          ),
          callback: (payload) {
            _conversationUpdateController.add(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to typing indicators for a conversation
  void subscribeToTyping(String conversationId) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _typingChannel?.unsubscribe();
    
    _typingChannel = _supabase
        .channel('typing:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'typing_indicators',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            // Only emit if it's not the current user typing
            if (payload.newRecord['user_id'] != userId) {
              _typingController.add(payload.newRecord);
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribe from all realtime channels
  void unsubscribeAll() {
    _messagesChannel?.unsubscribe();
    _conversationsChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
  }

  /// Dispose
  void dispose() {
    unsubscribeAll();
    _messageController.close();
    _conversationUpdateController.close();
    _typingController.close();
  }
}

