import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/theme_notifier.dart';
import 'features/auth/domain/auth_notifier.dart';
import 'features/auth/presentation/screens/lock_screen.dart';

class DiaryApp extends ConsumerStatefulWidget {
  const DiaryApp({super.key});

  @override
  ConsumerState<DiaryApp> createState() => _DiaryAppState();
}

class _DiaryAppState extends ConsumerState<DiaryApp> with WidgetsBindingObserver {
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final isGoingBackground = state == AppLifecycleState.paused || 
                              state == AppLifecycleState.inactive || 
                              state == AppLifecycleState.hidden;
                              
    if (isGoingBackground) {
      final authState = ref.read(authNotifierProvider);
      if (authState.isBiometricEnabled && !authState.isBypassed) {
        // İşletim sistemi arka plana alırken ekran resmini çekmeden önce hemen karartıyoruz
        setState(() => _isObscured = true);
        ref.read(authNotifierProvider.notifier).lockApp();
      }
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _isObscured = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(themeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

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
      builder: (context, child) {
        if (authState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Stack(
          children: [
            if (child != null) child,
            if (_isObscured || authState.isLocked) const LockScreen(),
          ],
        );
      },
    );
  }
}
