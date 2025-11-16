import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teacher/config/app_colors.dart';
import 'package:teacher/config/supabase_config.dart';
import 'package:teacher/screens/splash_screen.dart';
import 'package:teacher/screens/schedule/schedule_screen.dart';
import 'package:teacher/screens/sessions/sessions_screen.dart';
import 'package:teacher/services/presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _presenceService = PresenceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePresence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.stopTracking();
    _presenceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _presenceService.startTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background
        _presenceService.stopTracking();
        break;
    }
  }

  Future<void> _initializePresence() async {
    // Wait for auth to be ready
    await Future.delayed(const Duration(seconds: 2));
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _presenceService.startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lingumoro Teacher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/schedule': (context) => const ScheduleScreen(),
        '/sessions': (context) => const SessionsScreen(),
      },
    );
  }
}
