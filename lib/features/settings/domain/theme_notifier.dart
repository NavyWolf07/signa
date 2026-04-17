import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tüm tema ayarlarını bir arada tutan sınıf
class ThemeSettings {
  final ThemeMode themeMode;
  final Color seedColor;
  final double fontSize;

  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.seedColor = const Color(0xFF7C5CBF),
    this.fontSize = 1.0, // 1.0 = normal, 1.2 = büyük, 0.8 = küçük
  });

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    double? fontSize,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeSettings> {
  static const _modeKey = 'theme_mode';
  static const _colorKey = 'theme_color';
  static const _fontKey = 'theme_font_size';

  @override
  ThemeSettings build() {
    _load();
    return const ThemeSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final modeName = prefs.getString(_modeKey);
    final colorValue = prefs.getInt(_colorKey);
    final fontSize = prefs.getDouble(_fontKey);

    state = ThemeSettings(
      themeMode: modeName != null
          ? ThemeMode.values.firstWhere(
              (e) => e.name == modeName,
              orElse: () => ThemeMode.system,
            )
          : ThemeMode.system,
      seedColor: colorValue != null
          ? Color(colorValue)
          : const Color(0xFF7C5CBF),
      fontSize: fontSize ?? 1.0,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setSeedColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
    state = state.copyWith(seedColor: color);
  }

  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontKey, size);
    state = state.copyWith(fontSize: size);
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeSettings>(
  ThemeNotifier.new,
);

// Geriye dönük uyumluluk için — app.dart'ta kullanılıyor
final themeModeProvider = themeNotifierProvider;
