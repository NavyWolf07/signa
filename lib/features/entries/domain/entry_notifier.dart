import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/diary_entry.dart';
import '../data/repositories/entry_repository.dart';

// Repository'nin tek bir instance'ı olsun
final entryRepositoryProvider = Provider<EntryRepository>(
  (ref) => EntryRepository(),
);

// Girdilerin listesini tutan state
class EntryNotifier extends AsyncNotifier<List<DiaryEntry>> {
  late EntryRepository _repository;

  @override
  Future<List<DiaryEntry>> build() async {
    // Repository'yi al
    _repository = ref.watch(entryRepositoryProvider);
    // Veritabanındaki tüm girdileri yükle
    return await _repository.getAll();
  }

  // Yeni girdi ekle
  Future<void> addEntry(DiaryEntry entry) async {
    // Yükleniyor durumuna geç
    state = const AsyncLoading();
    // Veritabanına kaydet
    await _repository.insert(entry);
    // Listeyi yenile
    state = AsyncData(await _repository.getAll());
  }

  // Girdiyi güncelle
  Future<void> updateEntry(DiaryEntry entry) async {
    state = const AsyncLoading();
    await _repository.update(entry);
    state = AsyncData(await _repository.getAll());
  }

  // Girdiyi sil
  Future<void> deleteEntry(int id) async {
    state = const AsyncLoading();
    await _repository.delete(id);
    state = AsyncData(await _repository.getAll());
  }

  // Arama yap
  Future<void> search(String query) async {
    if (query.isEmpty) {
      // Arama boşsa tüm listeyi göster
      state = AsyncData(await _repository.getAll());
      return;
    }
    state = const AsyncLoading();
    state = AsyncData(await _repository.search(query));
  }
}

// Ekranların kullanacağı provider
final entryNotifierProvider =
    AsyncNotifierProvider<EntryNotifier, List<DiaryEntry>>(EntryNotifier.new);
