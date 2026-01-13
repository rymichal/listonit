import 'package:flutter/material.dart';

class ListColors {
  static const List<Color> presetColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF3F51B5), // Indigo
    Color(0xFF009688), // Teal
  ];

  static const List<String> presetColorHex = [
    '#4CAF50',
    '#2196F3',
    '#F44336',
    '#FF9800',
    '#9C27B0',
    '#00BCD4',
    '#E91E63',
    '#795548',
    '#607D8B',
    '#FFEB3B',
    '#3F51B5',
    '#009688',
  ];

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
