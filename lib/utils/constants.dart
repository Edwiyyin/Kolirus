import 'package:flutter/material.dart';

class AppColors {
  static const Color dark       = Color(0xFF121212); // Deep Dark
  static const Color primary    = Color(0xFF1E1E1E); // Surface Dark
  static const Color beige      = Color(0xFFF5F5DC); // Text/Highlights
  static const Color olive      = Color(0xFF808000); // Green Olive
  static const Color violet     = Color(0xFF8A2BE2); // Violet Accent
  
  static const Color background = dark;
  static const Color card       = primary;
  static const Color text       = beige;
  static const Color accent     = violet;
  static const Color success    = olive;
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.beige,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.beige,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, color: AppColors.beige,
  );
}
