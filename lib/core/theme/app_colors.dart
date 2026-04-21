import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Основные цвета
  static const Color primary = Color(0xFF6C63FF); // Яркий фиолетовый
  static const Color secondary = Color(0xFFFF6584); // Мягкий розовый
  static const Color accent = Color(0xFF43D9AD); // Мятный зеленый
  
  // Фон и поверхности
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Colors.white;
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Текст
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textLight = Colors.white;

  // Статусы
  static const Color success = Color(0xFF43D9AD);
  static const Color error = Color(0xFFFF6584);
  static const Color warning = Color(0xFFFFBC5C);

  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}