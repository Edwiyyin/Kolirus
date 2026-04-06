import 'package:flutter/material.dart';

class AppColors {
  // Purple family
  static const Color background    = Color(0xFF2A1733); // darkest purple
  static const Color card          = Color(0xFF3A2244); // mid-dark purple
  static const Color primary       = Color(0xFF4B2E57); // brand purple
  static const Color primaryLight  = Color(0xFF5E3D6B); // lighter purple
  static const Color primaryLighter = Color(0xFF6B4A78); // subtle purple accent

  // Olive family
  static const Color olive         = Color(0xFF808000); // brand olive
  static const Color oliveDark     = Color(0xFF606000); // deep olive
  static const Color oliveLight    = Color(0xFFA0A020); // bright olive

  // Beige / text family
  static const Color beige         = Color(0xFFDECD87); // brand beige (primary text)
  static const Color textMuted     = Color(0xFFC8B870); // secondary text
  static const Color textLight     = Color(0xFFF0E4A8); // light text / highlights

  // Status
  static const Color warning       = Color(0xFFE9A84A);
  static const Color danger        = Color(0xFFCF6679);

  // Aliases for backwards compatibility
  static const Color text          = beige;
  static const Color accent        = olive;
  static const Color secondary     = olive;
  static const Color success       = olive;
  static const Color dark          = background;
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
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );
}

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((str) => str.isNotEmpty
        ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
        : '')
        .join(' ');
  }
}