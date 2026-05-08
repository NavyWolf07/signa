import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isBiometricEnabled;
  final bool isLocked;
  final bool canCheckBiometrics;
  final bool isBypassed;

  const AuthState({
    this.isBiometricEnabled = false,
    this.isLocked = false,
    this.canCheckBiometrics = false,
    this.isBypassed = false,
  });

  AuthState copyWith({
    bool? isBiometricEnabled,
    bool? isLocked,
    bool? canCheckBiometrics,
    bool? isBypassed,
  }) {
    return AuthState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isLocked: isLocked ?? this.isLocked,
      canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
      isBypassed: isBypassed ?? this.isBypassed,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const _biometricKey = 'is_biometric_enabled';
  final LocalAuthentication auth = LocalAuthentication();

  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_biometricKey) ?? false;
    
    // Cihazın Biyometrik desteği var mı kontrolü
    bool canCheck = false;
    try {
      canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } on PlatformException catch (_) {
      canCheck = false;
    }

    state = state.copyWith(
      isBiometricEnabled: isEnabled,
      canCheckBiometrics: canCheck,
      isLocked: isEnabled, // Eğer açıksa başlangıçta direkt kilidi koy
    );
  }

  Future<void> toggleBiometric(bool value) async {
    if (value && !state.canCheckBiometrics) return; // Destek yoksa açılamasın
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
    state = state.copyWith(isBiometricEnabled: value);
  }

  // Biyometrik doğrulama iste
  Future<bool> authenticate() async {
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Cihaz parolası veya parmak izi okutunuz',
      );
      
      if (authenticated) {
        state = state.copyWith(isLocked: false);
      }
      return authenticated;
    } catch (e) {
      // Hem Native (PlatformException) hem de Dart kaynaklı iptallerde çökmeden geri dön
      return false;
    }
  }

  // Uygulama alta atıldığında kilitle
  void lockApp() {
    if (state.isBiometricEnabled && !state.isBypassed) {
      state = state.copyWith(isLocked: true);
    }
  }

  // Galeri veya kamera gibi sistem pencerelerinde kilidi atlamak için
  void setBypass(bool value) {
    state = state.copyWith(isBypassed: value);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
