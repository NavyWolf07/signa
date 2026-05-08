import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/diary_entry.dart';

class EntryRepository {
  // Tek bir veritabanı bağlantısı olsun diye
  static Database? _database;

  Future<Database> get database async {
    // Eğer zaten açıksa tekrar açma
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Veritabanı dosyasının telefondaki yolu
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'diary.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createTable,
      onUpgrade: _upgradeTable,
    );
  }

  // Veritabanı ilk oluşturulduğunda tabloyu kur
  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        mood TEXT NOT NULL DEFAULT 'neutral',
        tags TEXT,
        audioPath TEXT,
        documentContent TEXT,
        location TEXT,
        weather TEXT,
        images TEXT
      )
    ''');
  }

  // Mevcut veritabanını yeni sürüme taşı — veri kaybı olmadan
  Future<void> _upgradeTable(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2 migration
      await db.execute('ALTER TABLE entries ADD COLUMN documentContent TEXT');
    }
    if (oldVersion < 3) {
      // Version 3 migration
      await db.execute('ALTER TABLE entries ADD COLUMN location TEXT');
      await db.execute('ALTER TABLE entries ADD COLUMN weather TEXT');
    }
    if (oldVersion < 4) {
      // Version 4 migration
      await db.execute('ALTER TABLE entries ADD COLUMN images TEXT');
    }
  }

  // ── CRUD İşlemleri ──────────────────────────────

  // Yeni girdi kaydet
  Future<DiaryEntry> insert(DiaryEntry entry) async {
    final db = await database;
    final id = await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return entry.copyWith(id: id);
  }

  // Tüm girdileri getir — en yeni en üstte
  Future<List<DiaryEntry>> getAll() async {
    final db = await database;
    final maps = await db.query('entries', orderBy: 'createdAt DESC');
    return maps.map((map) => DiaryEntry.fromMap(map)).toList();
  }

  // Tek bir girdiyi id ile getir
  Future<DiaryEntry?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DiaryEntry.fromMap(maps.first);
  }

  // Girdiyi güncelle
  Future<DiaryEntry> update(DiaryEntry entry) async {
    final db = await database;
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await db.update(
      'entries',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    return updated;
  }

  // Girdiyi sil
  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  // Başlık, etiketler veya ruh hali üzerinden arama yap
  Future<List<DiaryEntry>> search(String query) async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'title LIKE ? OR tags LIKE ? OR mood LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => DiaryEntry.fromMap(map)).toList();
  }

  // Veritabanı bağlantısını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
