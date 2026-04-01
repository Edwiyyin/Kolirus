import 'package:flutter/material.dart';

class AppColors {
  // Theme: Dark Background + Olive Green Secondary
  static const Color dark       = Color(0xFF121212); 
  static const Color primary    = Color(0xFF1E1E1E); 
  static const Color olive      = Color(0xFF808000); // Olive Green
  static const Color beige      = Color(0xFFF5F5DC); 
  
  static const Color background = dark;
  static const Color card       = primary;
  static const Color text       = beige;
  static const Color secondary  = olive; // Using only olive as secondary
  static const Color accent     = olive; // Using only olive as accent
  
  static const Color textLight  = Color(0xFFD2D2A0);
  static const Color warning    = Color(0xFFE9C46A); 
  static const Color danger     = Color(0xFFCF6679);
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
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textLight,
  );
}
