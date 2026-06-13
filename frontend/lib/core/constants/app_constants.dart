// App Constants
import 'package:flutter/material.dart';

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'Sigap';
  static const String appVersion = '0.1.0';

  // Colors — Primary Palette
  static const Color primaryColor = Color(0xFF7BA8DC);
  static const Color primaryAlphaColor = Color(0x857BA8DC);

  // Colors — Semantic
  static const Color urgentColor = Color(0xFFDC2626);
  static const Color errorColor = urgentColor;
  static const Color successColor = Color(0xFF16A34A);

  // Colors — Surface & Background
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // Colors — Text
  static const Color textDark = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // API (uncomment when backend ready)
  // static const String baseUrl = 'http://localhost:8080/api';
}
