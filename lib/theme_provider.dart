import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  // 平台字体映射
  static const _platformFonts = {
    TargetPlatform.android: 'Noto Sans CJK SC',
    TargetPlatform.iOS: 'PingFang SC',
    TargetPlatform.windows: 'Source Han Sans SC',
    TargetPlatform.macOS: 'PingFang SC',
  };

  // 颜色配置
  static const _lightColors = {
    'primary': Color(0xFF6200EE),
    'onPrimary': Colors.white,
    'text': Colors.black87,
    'secondaryText': Colors.black54,
    'background': Colors.white,
  };

  static const _darkColors = {
    'primary': Color(0xFFBB86FC),
    'onPrimary': Colors.black,
    'text': Colors.white70,
    'secondaryText': Colors.white60,
    'background': Color(0xFF121212),
  };

  ThemeMode get themeMode => _themeMode;

  String? get platformFont => _platformFonts[defaultTargetPlatform];
  Color get textColor =>
      _themeMode == ThemeMode.dark
          ? _darkColors['text']!
          : _lightColors['text']!;
  Color get secondaryTextColor =>
      _themeMode == ThemeMode.dark
          ? _darkColors['secondaryText']!
          : _lightColors['secondaryText']!;

  TextTheme get _textTheme {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: platformFont,
        fontSize: 57,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontFamily: platformFont,
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontFamily: platformFont,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: platformFont,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: platformFont,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: platformFont,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: platformFont,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: platformFont,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontFamily: platformFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: platformFont,
        fontSize: 16,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: platformFont,
        fontSize: 14,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: platformFont,
        fontSize: 12,
        color: secondaryTextColor,
      ),
      labelLarge: TextStyle(
        fontFamily: platformFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontFamily: platformFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontFamily: platformFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
    );
  }

  ThemeData get lightTheme => ThemeData.light().copyWith(
    colorScheme: ColorScheme.light(
      primary: _lightColors['primary']!,
      onPrimary: _lightColors['onPrimary']!,
    ),
    textTheme: _textTheme,
    primaryTextTheme: _textTheme,
    typography: Typography.material2021(platform: defaultTargetPlatform),
  );

  ThemeData get darkTheme => ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: _darkColors['primary']!,
      onPrimary: _darkColors['onPrimary']!,
    ),
    textTheme: _textTheme,
    primaryTextTheme: _textTheme,
    typography: Typography.material2021(platform: defaultTargetPlatform),
  );

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
