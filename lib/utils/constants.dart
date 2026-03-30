import 'package:flutter/material.dart';

class AppColors {
  static const Color primary    = Color(0xFF5C4A32);
  static const Color secondary  = Color(0xFFA0785A);
  static const Color accent     = Color(0xFFC8BA96);
  static const Color card       = Color(0xFFD4C4A0);
  static const Color background = Color(0xFFE8DCC8);
  static const Color text       = Color(0xFF3A2810);
  static const Color textLight  = Color(0xFF7A6040);
  static const Color success    = Color(0xFF6B8C5A);
  static const Color warning    = Color(0xFFC87840);
  static const Color danger     = Color(0xFFA04030);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.text, letterSpacing: -0.5,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.text,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );
}