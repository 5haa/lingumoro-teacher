import 'package:flutter/material.dart';
import 'package:teacher/config/app_colors.dart';
import 'package:teacher/services/auth_service.dart';
import 'package:teacher/widgets/custom_button.dart';
import 'package:teacher/widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';

class SignUpContent extends StatefulWidget {
  const SignUpContent({super.key});

  @override
  State<SignUpContent> createState() => _SignUpContentState();
}

class _SignUpContentState extends State<SignUpContent> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSignUp() async {
    if (_fullNameController.text.isEmpty || 
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: null,
        bio: null,
        specialization: _specializationController.text.trim().isEmpty 
            ? null 
            : _specializationController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              email: _emailController.text.trim(),
              fullName: _fullNameController.text.trim(),
              phone: null,
              bio: null,
              specialization: _specializationController.text.trim().isEmpty 
                  ? null 
                  : _specializationController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full Name field
        CustomTextField(
          controller: _fullNameController,
          hintText: 'Full Name',
          keyboardType: TextInputType.name,
        ),
        
        const SizedBox(height: 20),
        
        // Email field
        CustomTextField(
          controller: _emailController,
          hintText: 'E-Mail',
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 20),
        
        // Specialization field (optional)
        CustomTextField(
          controller: _specializationController,
          hintText: 'Specialization (optional)',
          keyboardType: TextInputType.text,
        ),
        
        const SizedBox(height: 20),
        
        // Password field
        CustomTextField(
          controller: _passwordController,
          hintText: 'Password',
          obscureText: true,
        ),
        
        const SizedBox(height: 20),
        
        // Confirm Password field
        CustomTextField(
          controller: _confirmPasswordController,
          hintText: 'Confirm Password',
          obscureText: true,
        ),
        
        const SizedBox(height: 30),
        
        // Confirm Account button
        CustomButton(
          text: 'CONFIRM ACCOUNT',
          onPressed: _handleSignUp,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}

