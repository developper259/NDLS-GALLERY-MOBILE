import 'package:flutter/material.dart';

class AppConfig {
  // API Configuration
  static const String apiBaseUrl =
      "https://annual-sharai-ndl-0321241e.koyeb.app/api";
  static const String baseUrl = "https://annual-sharai-ndl-0321241e.koyeb.app";

  static const Map<String, String> endpoints = {
    'media': '/media',
    'storage': '/storage',
    'upload': '/media/upload',
    'trash': '/trash',
    'delete': '/media/{id}',
    'download': '/media/{id}/download',
    'albums': '/albums',
  };

  // Gallery Settings
  static const int itemsPerPage = 50;
  static const int columns = 4;
  static const double gap = 12.0;

  // UI Settings
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration toastDuration = Duration(seconds: 3);
  static const double lightboxBlur = 24.0;
  static const double hoverScale = 1.02;

  // Colors
  static const Color primary = Color(0xFF2563eb);
  static const Color primaryHover = Color(0xFF1d4ed8);
  static const Color background = Color(0xFFffffff);
  static const Color foreground = Color(0xFF0f172a);
  static const Color muted = Color(0xFFf1f5f9);
  static const Color mutedForeground = Color(0xFF64748b);
  static const Color border = Color(0xFFe2e8f0);
  static const Color danger = Color(0xFFef4444);
  static const Color success = Color(0xFF22c55e);
  static const Color warning = Color(0xFFf59e0b);
  static const Color overlay = Color.fromRGBO(0, 0, 0, 0.95);
}
