import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/theme_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Seçilebilecek renkler
  static const _colors = [
    Color(0xFF7C5CBF), // Mor
    Color(0xFF2196F3), // Mavi
    Color(0xFF4CAF50), // Yeşil
    Color(0xFFFF5722), // Turuncu
    Color(0xFFE91E63), // Pembe
    Color(0xFF009688), // Teal
    Color(0xFFFF9800), // Amber
    Color(0xFF607D8B), // Gri-Mavi
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeNotifierProvider);
    final notifier = ref.read(themeNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // GÖRÜNÜM BÖLÜMÜ
          _sectionTitle(context, 'GÖRÜNÜM'),

          RadioListTile<ThemeMode>(
            title: const Text('Sistem teması'),
            subtitle: const Text('Telefon ayarına göre değişir'),
            secondary: const Icon(Icons.brightness_auto_outlined),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (value) => notifier.setThemeMode(value!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Açık tema'),
            secondary: const Icon(Icons.light_mode_outlined),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (value) => notifier.setThemeMode(value!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Koyu tema'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (value) => notifier.setThemeMode(value!),
          ),

          const Divider(),

          // RENK BÖLÜMÜ
          _sectionTitle(context, 'ANA RENK'),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = settings.seedColor == color;
                return GestureDetector(
                  onTap: () => notifier.setSeedColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // FONT BOYUTU BÖLÜMÜ
          _sectionTitle(context, 'YAZI BOYUTU'),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('A', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: settings.fontSize,
                        min: 0.8,
                        max: 1.4,
                        divisions: 3,
                        onChanged: (value) => notifier.setFontSize(value),
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 20)),
                  ],
                ),
                // Önizleme
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Yazı boyutu önizlemesi',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // HAKKINDA BÖLÜMÜ
          _sectionTitle(context, 'HAKKINDA'),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Uygulama versiyonu'),
            trailing: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.book_outlined),
            title: Text('Diary'),
            subtitle: Text('Kişisel günlük uygulaması'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
