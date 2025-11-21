import 'package:flutter/material.dart';
import 'package:teacher/config/app_colors.dart';
import 'package:teacher/services/auth_service.dart';
import 'package:teacher/widgets/custom_button.dart';
import 'package:teacher/widgets/custom_text_field.dart';
import 'package:teacher/l10n/app_localizations.dart';
import 'forgot_password_screen.dart';
import '../main_navigation.dart';

class SignInContent extends StatefulWidget {
  const SignInContent({super.key});

  @override
  State<SignInContent> createState() => _SignInContentState();
}

class _SignInContentState extends State<SignInContent> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSignIn() async {
    final l10n = AppLocalizations.of(context);
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.email} ${l10n.and} ${l10n.password} ${l10n.fieldRequired}'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainNavigation(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).loginFailed}: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally{
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _handleForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Email field
        CustomTextField(
          controller: _emailController,
          hintText: '${l10n.email} ${l10n.or} ${l10n.phoneNumber}',
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 20),
        
        // Password field
        CustomTextField(
          controller: _passwordController,
          hintText: l10n.password,
          obscureText: true,
        ),
        
        const SizedBox(height: 30),
        
        // Sign In button
        CustomButton(
          text: l10n.login.toUpperCase(),
          onPressed: _handleSignIn,
          isLoading: _isLoading,
        ),
        
        const SizedBox(height: 20),
        
        // Forgot Password button
        TextButton(
          onPressed: _handleForgotPassword,
          child: Text(
            l10n.forgotPassword,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}







