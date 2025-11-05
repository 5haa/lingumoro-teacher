import 'package:flutter/material.dart';
import 'package:teacher/services/timeslot_service.dart';
import 'package:teacher/services/auth_service.dart';

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
          backgroundColor: Colors.green,
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
          backgroundColor: Colors.green,
        ),
      );
      _loadTimeslots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage 30-Min Timeslots'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTimeslots,
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
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade400, Colors.teal.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Timeslots Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                _stats['total'] ?? 0,
                Icons.calendar_today,
                Colors.white,
              ),
              _buildStatItem(
                'Available',
                _stats['available'] ?? 0,
                Icons.check_circle,
                Colors.white,
              ),
              _buildStatItem(
                'Disabled',
                _stats['disabled'] ?? 0,
                Icons.cancel,
                Colors.white70,
              ),
              _buildStatItem(
                'Booked',
                _stats['occupied'] ?? 0,
                Icons.event_busy,
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Timeslots Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a schedule to generate 30-min timeslots',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeslotsList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: _timeslots.entries.map((entry) {
        final dayOfWeek = entry.key;
        final slots = entry.value;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.calendar_today,
            color: Colors.teal.shade700,
          ),
        ),
        title: Text(
          _dayNames[dayOfWeek],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${slots.length} slots: $availableCount available, $occupiedCount booked',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'enable_all',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Enable All'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'disable_all',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Disable All'),
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
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              return _buildTimeslotChip(slot);
            }).toList(),
          ),
        ],
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
      icon = Icons.event_busy;
    } else if (isAvailable) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
    } else {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
      icon = Icons.cancel;
    }

    return InkWell(
      onTap: () => _toggleTimeslot(slot['id'], isAvailable, isOccupied),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
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






