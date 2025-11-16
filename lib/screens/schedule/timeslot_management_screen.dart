import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/app_colors.dart';
import '../../widgets/custom_back_button.dart';
import '../../services/timeslot_service.dart';
import '../../services/auth_service.dart';

class TimeslotManagementScreen extends StatefulWidget {
  const TimeslotManagementScreen({super.key});

  @override
  State<TimeslotManagementScreen> createState() =>
      _TimeslotManagementScreenState();
}

class _TimeslotManagementScreenState extends State<TimeslotManagementScreen> {
  final _timeslotService = TimeslotService();
  final _authService = AuthService();

  Map<int, List<Map<String, dynamic>>> _timeslots = {};
  Map<String, int> _stats = {};
  bool _isLoading = true;

  final List<String> _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _loadTimeslots();
  }

  Future<void> _loadTimeslots() async {
    setState(() => _isLoading = true);

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final timeslots =
          await _timeslotService.getTeacherTimeslots(currentUser.id);
      final stats = await _timeslotService.getTimeslotStats(currentUser.id);

      setState(() {
        _timeslots = timeslots;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTimeslot(
      String timeslotId, bool currentStatus, bool isOccupied) async {
    if (isOccupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot disable occupied timeslot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success =
        await _timeslotService.toggleTimeslot(timeslotId, !currentStatus);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Timeslot ${!currentStatus ? "enabled" : "disabled"} successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadTimeslots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update timeslot'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkToggleDay(int dayOfWeek, bool enable) async {
    final daySlots = _timeslots[dayOfWeek] ?? [];
    final unoccupiedSlots = daySlots
        .where((slot) => slot['is_occupied'] == false)
        .map((slot) => slot['id'] as String)
        .toList();

    if (unoccupiedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available slots to toggle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success =
        await _timeslotService.bulkToggleTimeslots(unoccupiedSlots, enable);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${unoccupiedSlots.length} timeslots ${enable ? "enabled" : "disabled"}'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadTimeslots();
    }
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
                  const CustomBackButton(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'MANAGE TIMESLOTS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 45),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTimeslots,
                      color: AppColors.primary,
                      child: Column(
                        children: [
                          _buildStatsCard(),
                          Expanded(
                            child: _timeslots.isEmpty
                                ? _buildEmptyState()
                                : _buildTimeslotsList(),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.greenGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.chartLine,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Timeslots Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                _stats['total'] ?? 0,
                FontAwesomeIcons.calendarDays,
              ),
              _buildStatItem(
                'Available',
                _stats['available'] ?? 0,
                FontAwesomeIcons.circleCheck,
              ),
              _buildStatItem(
                'Disabled',
                _stats['disabled'] ?? 0,
                FontAwesomeIcons.circleXmark,
              ),
              _buildStatItem(
                'Booked',
                _stats['occupied'] ?? 0,
                FontAwesomeIcons.calendarCheck,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              FontAwesomeIcons.clock,
              size: 40,
              color: AppColors.grey.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Timeslots Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add a schedule to generate 30-min timeslots',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeslotsList() {
    // Sort days
    final sortedDays = _timeslots.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: sortedDays.map((dayOfWeek) {
        final slots = _timeslots[dayOfWeek]!;
        return _buildDayCard(dayOfWeek, slots);
      }).toList(),
    );
  }

  Widget _buildDayCard(int dayOfWeek, List<Map<String, dynamic>> slots) {
    final availableCount =
        slots.where((s) => s['is_available'] == true && s['is_occupied'] == false).length;
    final disabledCount =
        slots.where((s) => s['is_available'] == false).length;
    final occupiedCount = slots.where((s) => s['is_occupied'] == true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        childrenPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.greenGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.calendarDays,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        title: Text(
          _dayNames[dayOfWeek],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildStatusBadge('$availableCount available', AppColors.primary),
              _buildStatusBadge('$occupiedCount booked', Colors.orange),
              _buildStatusBadge('$disabledCount disabled', AppColors.grey),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const FaIcon(
            FontAwesomeIcons.ellipsisVertical,
            size: 18,
            color: AppColors.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppColors.white,
          elevation: 8,
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'enable_all',
              child: const Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleCheck,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Enable All',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'disable_all',
              child: const Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleXmark,
                    color: Colors.orange,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Disable All',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'enable_all') {
              _bulkToggleDay(dayOfWeek, true);
            } else if (value == 'disable_all') {
              _bulkToggleDay(dayOfWeek, false);
            }
          },
        ),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((slot) {
              return _buildTimeslotChip(slot);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTimeslotChip(Map<String, dynamic> slot) {
    final startTime = slot['start_time'] as String;
    final endTime = slot['end_time'] as String;
    final isAvailable = slot['is_available'] as bool;
    final isOccupied = slot['is_occupied'] as bool;

    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (isOccupied) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = FontAwesomeIcons.calendarCheck;
    } else if (isAvailable) {
      backgroundColor = AppColors.primary.withOpacity(0.1);
      textColor = AppColors.primary;
      icon = FontAwesomeIcons.circleCheck;
    } else {
      backgroundColor = AppColors.lightGrey.withOpacity(0.5);
      textColor = AppColors.textSecondary;
      icon = FontAwesomeIcons.circleXmark;
    }

    return InkWell(
      onTap: () => _toggleTimeslot(slot['id'], isAvailable, isOccupied),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 14, color: textColor),
            const SizedBox(width: 8),
            Text(
              '${_formatTime(startTime)}-${_formatTime(endTime)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];

      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute$period';
    } catch (e) {
      return time;
    }
  }
}
