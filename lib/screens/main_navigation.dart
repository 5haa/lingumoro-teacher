import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:teacher/config/app_colors.dart';
import 'package:teacher/widgets/app_drawer.dart';
import 'package:teacher/l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'classes/classes_screen.dart';
import 'students/students_screen.dart';
import 'chat/chat_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _initScreens();
  }
  
  void _initScreens() {
    _screens = [
      HomeScreen(onTabChange: _onTabChange),
      const ClassesScreen(),
      const StudentsScreen(),
      const ChatScreen(),
      const ProfileScreen(),
    ];
  }
  
  void _onTabChange(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
  
  List<Map<String, dynamic>> _getNavItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      {
        'icon': FontAwesomeIcons.house,
        'label': l10n.navHome,
      },
      {
        'icon': FontAwesomeIcons.graduationCap,
        'label': l10n.navClasses,
      },
      {
        'icon': FontAwesomeIcons.userGroup,
        'label': l10n.students,
      },
      {
        'icon': FontAwesomeIcons.message,
        'label': l10n.navChat,
      },
      {
        'icon': FontAwesomeIcons.user,
        'label': l10n.navProfile,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_getNavItems(context).length, (index) {
                final navItems = _getNavItems(context);
                return _buildNavItem(
                  navItems[index]['icon'],
                  navItems[index]['label'],
                  index,
                  _currentIndex == index,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, int index, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.greenGradient : null,
              color: isActive ? null : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              icon,
              color: isActive ? AppColors.white : AppColors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppColors.primary : AppColors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
