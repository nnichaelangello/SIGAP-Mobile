import 'package:flutter/material.dart';

class NotificationRecord {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final String section;
  final bool isUnread;

  const NotificationRecord({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.section,
    this.isUnread = false,
  });

  NotificationRecord copyWith({
    String? id,
    IconData? icon,
    Color? iconColor,
    String? title,
    String? body,
    String? time,
    String? section,
    bool? isUnread,
  }) {
    return NotificationRecord(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      section: section ?? this.section,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}
