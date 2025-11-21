import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teacher/services/firebase_notification_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _firebaseNotificationService = FirebaseNotificationService();

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up a new teacher (sends OTP to email)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? bio,
    String? specialization,
  }) async {
    // Check if email already exists in auth.users table
    final emailExistsResponse = await _supabase
        .rpc('check_email_exists', params: {'check_email': email});

    if (emailExistsResponse == true) {
      throw Exception('This email is already registered. Please login instead.');
    }

    // Sign up user - this will send OTP email
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: null, // Disable email link
    );

    // Note: User data will be passed via the OTP screen
    // Profile will be created after OTP verification when user has a session

    return response;
  }

  /// Verify OTP and create profile
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required String fullName,
    String? phone,
    String? bio,
    String? specialization,
  }) async {
    // Verify the OTP - this will create an authenticated session
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: token,
    );

    // Create teacher profile after successful verification
    if (response.user != null) {
      // Check if profile already exists
      final existing = await _supabase
          .from('teachers')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('teachers').insert({
          'id': response.user!.id,
          'email': response.user!.email,
          'full_name': fullName,
          'phone': phone,
          'bio': bio,
          'specialization': specialization,
        });
      }
      
      // Initialize Firebase notifications
      try {
        await _firebaseNotificationService.initialize();
        print('✅ Firebase notifications initialized successfully');
      } catch (e) {
        print('❌ Failed to initialize Firebase notifications: $e');
      }
    }

    return response;
  }

  /// Resend OTP
  Future<void> resendOTP(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Check if account is suspended
    if (response.user != null) {
      await _checkSuspensionStatus(response.user!.id);
      
      // Initialize Firebase notifications
      try {
        await _firebaseNotificationService.initialize();
        print('✅ Firebase notifications initialized successfully');
      } catch (e) {
        print('❌ Failed to initialize Firebase notifications: $e');
      }
    }

    return response;
  }

  /// Check if user account is suspended
  Future<void> _checkSuspensionStatus(String userId) async {
    final teacher = await _supabase
        .from('teachers')
        .select('is_suspended, suspension_reason')
        .eq('id', userId)
        .maybeSingle();

    if (teacher != null && (teacher['is_suspended'] == true)) {
      // Sign out the user immediately
      await _supabase.auth.signOut();
      
      final reason = teacher['suspension_reason'] ?? 'Your account has been suspended.';
      throw Exception('Account suspended: $reason');
    }
  }

  /// Check suspension status for current user (call on app startup)
  Future<bool> checkIfSuspended() async {
    if (currentUser == null) return false;

    try {
      final teacher = await _supabase
          .from('teachers')
          .select('is_suspended, suspension_reason')
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (teacher != null && (teacher['is_suspended'] == true)) {
        await _supabase.auth.signOut();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get teacher profile
  Future<Map<String, dynamic>?> getTeacherProfile() async {
    if (currentUser == null) return null;

    final response = await _supabase
        .from('teachers')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();

    return response;
  }

  /// Update teacher profile
  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? specialization,
  }) async {
    if (currentUser == null) throw Exception('No user logged in');

    await _supabase.from('teachers').update({
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      if (specialization != null) 'specialization': specialization,
    }).eq('id', currentUser!.id);
  }

  /// Update teacher profile with all fields
  Future<void> updateTeacherProfile(Map<String, dynamic> data) async {
    if (currentUser == null) throw Exception('No user logged in');

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Add only provided fields
    if (data.containsKey('full_name')) updateData['full_name'] = data['full_name'];
    if (data.containsKey('phone')) updateData['phone'] = data['phone'];
    if (data.containsKey('avatar_url')) updateData['avatar_url'] = data['avatar_url'];
    if (data.containsKey('bio')) updateData['bio'] = data['bio'];
    if (data.containsKey('specialization')) updateData['specialization'] = data['specialization'];
    if (data.containsKey('intro_video_url')) updateData['intro_video_url'] = data['intro_video_url'];
    if (data.containsKey('meeting_link')) updateData['meeting_link'] = data['meeting_link'];

    await _supabase.from('teachers').update(updateData).eq('id', currentUser!.id);
  }

  /// Update teacher's default meeting link (will automatically update all upcoming sessions)
  Future<void> updateMeetingLink(String meetingLink) async {
    if (currentUser == null) throw Exception('No user logged in');

    await _supabase.from('teachers').update({
      'meeting_link': meetingLink,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', currentUser!.id);
  }

  /// Reset password (sends OTP)
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Verify password reset OTP
  Future<AuthResponse> verifyPasswordResetOTP({
    required String email,
    required String token,
  }) async {
    // Verify the password reset OTP
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: token,
    );

    return response;
  }

  /// Resend password reset OTP
  Future<void> resendPasswordResetOTP(String email) async {
    await _supabase.auth.resend(
      type: OtpType.recovery,
      email: email,
    );
  }

  /// Update password after OTP verification
  Future<void> updatePassword(String newPassword) async {
    if (currentUser == null) {
      throw Exception('No user logged in. Please verify OTP first.');
    }

    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Request OTP for changing password (when logged in)
  Future<void> requestChangePasswordOTP() async {
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    // Send OTP to the current user's email
    await _supabase.auth.resetPasswordForEmail(currentUser!.email!);
  }
}

