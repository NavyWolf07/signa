import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/audio_service.dart';

// Ses kaydının durumu
enum AudioState {
  idle, // Kayıt yok
  recording, // Kayıt yapılıyor
  stopped, // Kayıt durdu
}

class AudioNotifierState {
  final AudioState audioState;
  final List<String> recordedPaths; // Kaydedilen dosyaların yolları
  final String? error;
  final Duration recordingDuration;
  final double currentAmplitude;
  final List<double> amplitudeHistory;

  const AudioNotifierState({
    this.audioState = AudioState.idle,
    this.recordedPaths = const [],
    this.error,
    this.recordingDuration = Duration.zero,
    this.currentAmplitude = -160.0,
    this.amplitudeHistory = const [],
  });

  AudioNotifierState copyWith({
    AudioState? audioState,
    List<String>? recordedPaths,
    String? error,
    Duration? recordingDuration,
    double? currentAmplitude,
    List<double>? amplitudeHistory,
  }) {
    return AudioNotifierState(
      audioState: audioState ?? this.audioState,
      recordedPaths: recordedPaths ?? this.recordedPaths,
      error: error ?? this.error,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
      amplitudeHistory: amplitudeHistory ?? this.amplitudeHistory,
    );
  }
}

class AudioNotifier extends Notifier<AudioNotifierState> {
  late AudioService _audioService;
  StreamSubscription? _amplitudeSub;
  Timer? _timer;

  @override
  AudioNotifierState build() {
    _audioService = AudioService();
    // Widget kapanınca temizle
    ref.onDispose(() {
      _timer?.cancel();
      _amplitudeSub?.cancel();
      _audioService.dispose();
    });
    return const AudioNotifierState();
  }

  // Kaydı başlat
  Future<void> startRecording() async {
    try {
      await _audioService.startRecording();
      state = state.copyWith(
        audioState: AudioState.recording,
        recordingDuration: Duration.zero,
        currentAmplitude: -160.0,
        amplitudeHistory: [],
      );

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = state.copyWith(
          recordingDuration: Duration(seconds: timer.tick),
        );
      });

      _amplitudeSub?.cancel();
      _amplitudeSub = _audioService.getAmplitudeStream().listen((amp) {
        final newHistory = List<double>.from(state.amplitudeHistory)..add(amp.current);
        if (newHistory.length > 30) {
          newHistory.removeAt(0); // Sadece son 30 veriyi tut
        }
        state = state.copyWith(currentAmplitude: amp.current, amplitudeHistory: newHistory);
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Kaydı durdur
  Future<void> stopRecording() async {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    try {
      final filePath = await _audioService.stopRecording();
      if (filePath != null) {
        state = state.copyWith(
          audioState: AudioState.stopped,
          recordedPaths: [...state.recordedPaths, filePath],
          recordingDuration: Duration.zero,
        );
      } else {
        state = state.copyWith(
          audioState: AudioState.idle,
          recordingDuration: Duration.zero,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Kaydı iptal et
  Future<void> cancelRecording() async {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    await _audioService.cancelRecording();
    state = state.copyWith(
      audioState: AudioState.idle,
      recordingDuration: Duration.zero,
    );
  }

  // Eski kayıtları yükle
  void setRecordedPaths(List<String> paths) {
    state = state.copyWith(recordedPaths: paths);
  }

  // Belirli bir kaydı sil
  void removeRecording(String path) {
    final newList = state.recordedPaths.where((p) => p != path).toList();
    state = state.copyWith(recordedPaths: newList);
  }

  // Durumu sıfırla
  void reset() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    state = const AudioNotifierState();
  }
}

final audioNotifierProvider =
    NotifierProvider<AudioNotifier, AudioNotifierState>(AudioNotifier.new);
