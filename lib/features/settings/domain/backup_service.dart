import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import '../../entries/data/repositories/entry_repository.dart';
import '../../entries/domain/entry_notifier.dart';
import '../../auth/domain/auth_notifier.dart';

class BackupService {
  final EntryRepository _repository;

  BackupService(this._repository);

  // Yedeği Oluştur ve Paylaş
  Future<bool> exportBackup(WidgetRef ref) async {
    try {
      final archive = Archive();

      // 1. Veritabanı dosyasını bul ve arşive ekle
      final dbPath = await _repository.getDatabaseFilePath();
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        final dbBytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile('diary.db', dbBytes.length, dbBytes));
      }

      // 2. Medya dosyalarını bul (Resimler ve Ses kayıtları)
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync();
      
      for (var file in files) {
        if (file is File) {
          final fileName = p.basename(file.path);
          // Sadece diary_img ve audio ile başlayan dosyalarımız
          if (fileName.startsWith('diary_img_') || fileName.startsWith('audio_')) {
            final fileBytes = await file.readAsBytes();
            archive.addFile(ArchiveFile(fileName, fileBytes.length, fileBytes));
          }
        }
      }

      // 3. Arşivi ZIP formatında şifrele (encode)
      final zipData = ZipEncoder().encode(archive);

      // 4. Geçici klasöre .diarybackup uzantılı olarak kaydet
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
      final backupFileName = 'Gunluk_$dateStr.diarybackup';
      final backupFile = File(p.join(tempDir.path, backupFileName));
      
      await backupFile.writeAsBytes(zipData);

      // 5. Share Plus ile dosyayı paylaşırken kilitlenmeyi önle
      ref.read(authNotifierProvider.notifier).setBypass(true);
      final result = await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Günlük Yedeği ($dateStr)',
        text: 'Bu dosya günlüğünüzün şifreli yedeğidir. Uygulama içerisinden "Geri Yükle" seçeneği ile açabilirsiniz.',
      );
      ref.read(authNotifierProvider.notifier).setBypass(false);

      return result.status == ShareResultStatus.success;
    } catch (e) {
      ref.read(authNotifierProvider.notifier).setBypass(false);
      print('Backup Export Error: $e');
      return false;
    }
  }

  // Yedeği Seç ve Geri Yükle
  Future<String> importBackup(WidgetRef ref) async {
    try {
      // 1. Kullanıcıdan .diarybackup dosyasını seçmesini iste
      ref.read(authNotifierProvider.notifier).setBypass(true);
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.any,
      );
      ref.read(authNotifierProvider.notifier).setBypass(false);

      if (result == null || result.files.isEmpty) {
        return 'canceled'; // Kullanıcı iptal etti
      }

      final file = result.files.first;
      final backupPath = file.path;
      if (backupPath == null) return 'Dosya yolu bulunamadı.';

      // 2. Dosyayı oku ve Archive'i çöz (unzip)
      final bytes = await File(backupPath).readAsBytes();
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
        // Geçerli bir yedek olup olmadığını kontrol edelim
        if (!archive.any((f) => f.name == 'diary.db')) {
          return 'Seçilen dosya geçerli bir günlük yedeği değil.';
        }
      } catch (e) {
        return 'Geçersiz dosya formatı. Lütfen geçerli bir yedekleme dosyası (.diarybackup) seçin.';
      }

      // 3. Güvenlik için SQLite veritabanını kapat (Üzerine yazarken çakışmaması için)
      await _repository.closeDatabase();

      final dbPath = await _repository.getDatabaseFilePath();
      final appDir = await getApplicationDocumentsDirectory();

      // 4. Arşivdeki dosyaları yerlerine kopyala
      for (final archiveFile in archive) {
        if (archiveFile.isFile) {
          final data = archiveFile.content as List<int>;
          final name = archiveFile.name;

          if (name == 'diary.db') {
            // Veritabanını eski yerine yaz
            await File(dbPath).writeAsBytes(data, flush: true);
          } else {
            // Medya dosyalarını Documents klasörüne yaz
            final filePath = p.join(appDir.path, name);
            await File(filePath).writeAsBytes(data, flush: true);
          }
        }
      }

      // 5. Arayüzü güncelle (Riverpod statelerini sıfırla)
      ref.invalidate(entryNotifierProvider);

      return 'success';
    } catch (e) {
      ref.read(authNotifierProvider.notifier).setBypass(false);
      print('Backup Import Error: $e');
      return 'Yedek geri yüklenirken bir hata oluştu.';
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final repository = ref.watch(entryRepositoryProvider);
  return BackupService(repository);
});
