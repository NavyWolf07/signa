import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/theme_notifier.dart';

class DiaryApp extends ConsumerWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: 'Diary',
      debugShowCheckedModeBanner: false,
      // Lokalizasyon — Türkçe + flutter_quill araç çubuğu çevirileri
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      locale: const Locale('tr'),
      theme: AppTheme.light(
        seedColor: settings.seedColor,
        fontScale: settings.fontSize,
      ),
      darkTheme: AppTheme.dark(
        seedColor: settings.seedColor,
        fontScale: settings.fontSize,
      ),
      themeMode: settings.themeMode,
      routerConfig: appRouter,
    );
  }
}
