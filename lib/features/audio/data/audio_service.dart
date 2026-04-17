import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  // Kayıt var mı?
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // Kaydı başlat — dosya yolunu döndürür
  Future<String> startRecording() async {
    // İzin kontrolü
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Mikrofon izni verilmedi.');
    }

    // Dosyanın kaydedileceği klasör
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final filePath = path.join(dir.path, fileName);

    // Kaydı başlat
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    return filePath;
  }

  // Kaydı durdur — dosya yolunu döndürür
  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  // Sesin şiddeti/basıncı
  Stream<Amplitude> getAmplitudeStream() {
    return _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));
  }

  // Kaydı iptal et
  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  // Kaynakları serbest bırak
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
