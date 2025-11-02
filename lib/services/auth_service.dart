import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
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

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}

