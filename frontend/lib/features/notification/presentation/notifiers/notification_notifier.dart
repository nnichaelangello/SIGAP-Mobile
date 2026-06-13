import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../data/models/notification_record.dart';
import 'package:intl/intl.dart';

/// Single source of truth untuk seluruh state notifikasi.
class NotificationNotifier extends ChangeNotifier {
  List<NotificationRecord> _notifications = [];
  List<NotificationRecord> get notifications =>
      List.unmodifiable(_notifications);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.instance.get('/notifications');
      if (response.success && response.data != null) {
        final List<dynamic> data = (response.data!['data'] as List?) ?? [];
        _notifications = data.map((item) => _parseNotification(item)).toList();
      } else {
        _notifications = [];
      }
    } catch (e) {
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  NotificationRecord _parseNotification(Map<String, dynamic> json) {
    final nType = json['type'] ?? 'info';
    IconData icon = Icons.info_outline;
    Color iconColor = AppConstants.primaryColor;

    if (nType == 'emergency') {
      icon = Icons.warning_amber_rounded;
      iconColor = AppConstants.urgentColor;
    } else if (nType == 'report') {
      icon = Icons.assignment_rounded;
      iconColor = AppConstants.primaryColor;
    } else if (nType == 'report_update') {
      icon = Icons.sync_rounded;
      iconColor = AppConstants.successColor;
    } else if (nType == 'system') {
      icon = Icons.settings_rounded;
      iconColor = Colors.blueGrey;
    }

    DateTime date;
    try {
      date = DateTime.parse(json['created_at']).toLocal();
    } catch (_) {
      date = DateTime.now();
    }

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year && date.month == now.month && date.day == now.day - 1;
    
    String section = 'Lebih Lama';
    if (isToday) {
      section = 'Hari Ini';
    } else if (isYesterday) {
      section = 'Kemarin';
    }

    return NotificationRecord(
      id: json['id'].toString(),
      icon: icon,
      iconColor: iconColor,
      title: json['title'] ?? 'Notifikasi',
      body: json['body'] ?? '',
      time: DateFormat('HH:mm').format(date),
      section: section,
      isUnread: json['is_read'] == false,
    );
  }

  Future<void> markAllAsRead() async {
    final previousState = List<NotificationRecord>.from(_notifications);

    try {
      _notifications = _notifications.map((n) {
        return n.isUnread ? n.copyWith(isUnread: false) : n;
      }).toList();
      notifyListeners();

      await ApiService.instance.post('/notifications/mark-read', {'mark_all': true});
    } catch (e) {
      _notifications = previousState;
      notifyListeners();
      rethrow; 
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && _notifications[index].isUnread) {
        _notifications[index] = _notifications[index].copyWith(isUnread: false);
        notifyListeners();
        
        await ApiService.instance.post('/notifications/mark-read', {
          'notification_id': int.tryParse(id) ?? 0,
          'mark_all': false,
        });
      }
    } catch (_) {
    }
  }

  Future<void> removeNotification(String id) async {
    // Currently backend doesn't support DELETE notification, so we just hide it locally
    final removedIndex = _notifications.indexWhere((n) => n.id == id);
    if (removedIndex == -1) return;

    _notifications.removeAt(removedIndex);
    notifyListeners();
  }
}
