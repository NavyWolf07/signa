import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/theme_notifier.dart';
import '../../domain/backup_service.dart';
import '../../../auth/domain/auth_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
        title: Text(
          'Ayarlar',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TEMA GÖRÜNÜMÜ ──
            _buildSection(
              context,
              title: 'GÖRÜNÜM TASARIMI',
              child: _buildThemeSelection(context, settings, notifier),
            ),

            // ── ANA RENK ──
            _buildSection(
              context,
              title: 'UYGULAMA RENGİ',
              child: _buildColorSelection(context, settings, notifier),
            ),

            // ── YAZI BOYUTU ──
            _buildSection(
              context,
              title: 'TİPOGRAFİ & BOYUT',
              child: Column(
                children: [
                  _buildFontPreview(context),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.text_fields_rounded, size: 16),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: theme.colorScheme.primary,
                            inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            thumbColor: theme.colorScheme.primary,
                            trackHeight: 6,
                            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: settings.fontSize,
                            min: 0.8,
                            max: 1.4,
                            divisions: 3,
                            onChanged: (value) => notifier.setFontSize(value),
                          ),
                        ),
                      ),
                      const Icon(Icons.text_fields_rounded, size: 24),
                    ],
                  ),
                ],
              ),
            ),

            // ── VERİ VE YEDEKLEME ──
            _buildSection(
              context,
              title: 'VERİ VE YEDEKLEME',
              child: Consumer(
                builder: (context, ref, child) {
                  final backupService = ref.watch(backupServiceProvider);
                  final localTheme = Theme.of(context);
                  
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: localTheme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.upload_file_rounded, color: localTheme.colorScheme.primary),
                        ),
                        title: const Text('Yedek Oluştur ve Dışa Aktar', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Tüm anıları güvenli bir şekilde kaydeder.', style: TextStyle(fontSize: 12)),
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Yedek hazırlanıyor, lütfen bekleyin...')),
                          );
                          final success = await backupService.exportBackup(ref);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Yedek başarıyla oluşturuldu!')),
                            );
                          }
                        },
                      ),
                      const Divider(height: 16, thickness: 0.5),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: localTheme.colorScheme.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.download_rounded, color: localTheme.colorScheme.tertiary),
                        ),
                        title: const Text('Yedeği Geri Yükle', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Kayıtlı yedekleme dosyasını içeri aktarır.', style: TextStyle(fontSize: 12)),
                        onTap: () async {
                          final result = await backupService.importBackup(ref);
                          if (context.mounted) {
                            if (result == 'success') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Yedek başarıyla geri yüklendi! Ana sayfaya dönebilirsiniz.')),
                              );
                            } else if (result != 'canceled') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── GÜVENLİK ──
            _buildSection(
              context,
              title: 'GÜVENLİK (KİLİT)',
              child: Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authNotifierProvider);
                  final authNotifier = ref.read(authNotifierProvider.notifier);
                  final localTheme = Theme.of(context);
                  
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Biyometrik Kilit (Şifre)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      authState.canCheckBiometrics
                        ? 'Her girişte şifre / parmak izi sorulur.'
                        : 'Cihazınızda ekran şifresi / biyometrik güvenlik yok.',
                      style: TextStyle(fontSize: 12, color: localTheme.colorScheme.onSurfaceVariant),
                    ),
                    value: authState.isBiometricEnabled,
                    activeTrackColor: localTheme.colorScheme.primary.withValues(alpha: 0.5),
                    activeThumbColor: localTheme.colorScheme.primary,
                    onChanged: authState.canCheckBiometrics 
                      ? (value) => authNotifier.toggleBiometric(value)
                      : null,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: authState.isBiometricEnabled
                            ? localTheme.colorScheme.primary.withValues(alpha: 0.1)
                            : localTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded, 
                        color: authState.isBiometricEnabled
                            ? localTheme.colorScheme.primary
                            : localTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── HAKKINDA ──
            _buildSection(
              context,
              title: 'HAKKINDA',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                    ),
                    title: const Text('Uygulama Versiyonu', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('1.0.0', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.book_outlined, color: theme.colorScheme.tertiary),
                    ),
                    title: const Text('Uygulama Hakkında', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Kişisel Günlük Asistanı'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.alphaBlend(theme.colorScheme.primary.withValues(alpha: 0.05), theme.colorScheme.surface),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelection(BuildContext context, ThemeSettings settings, ThemeNotifier notifier) {
    return Row(
      children: [
        _buildThemeOption(context, settings, notifier, ThemeMode.system, 'Sistem', Icons.brightness_auto_rounded),
        const SizedBox(width: 12),
        _buildThemeOption(context, settings, notifier, ThemeMode.light, 'Açık', Icons.light_mode_rounded),
        const SizedBox(width: 12),
        _buildThemeOption(context, settings, notifier, ThemeMode.dark, 'Koyu', Icons.dark_mode_rounded),
      ],
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeSettings settings, ThemeNotifier notifier, ThemeMode mode, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = settings.themeMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon, 
                  key: ValueKey(isSelected),
                  color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelection(BuildContext context, ThemeSettings settings, ThemeNotifier notifier) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: _colors.map((color) {
          final isSelected = settings.seedColor == color;
          return GestureDetector(
            onTap: () => notifier.setSeedColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isSelected ? 52 : 44,
              height: isSelected ? 52 : 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isSelected ? 0.4 : 0.2),
                    blurRadius: isSelected ? 12 : 4,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.0 : 0.0,
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontPreview(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15), 
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_stories_rounded, size: 14, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Mükemmel Bir Gün',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bugün çok güzel bir gündü. Kütüphanede yeni bir kitap okumaya başladım ve uzun zamandır hissetmediğim kadar huzurlu hissettim. Bazen sadece durup küçük detayların tadını çıkarmak gerekiyor.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
