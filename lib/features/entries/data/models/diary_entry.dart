class DiaryEntry {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String mood;
  final List<String> tags;
  final String? audioPath;
  final String? location;
  final String? weather;
  // Zengin metin formatındaki içerik (flutter_quill JSON)
  final String? documentContent;

  const DiaryEntry({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.mood = 'neutral',
    this.tags = const [],
    this.audioPath,
    this.location,
    this.weather,
    this.documentContent,
  });

  // Veritabanına kaydetmek için Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'mood': mood,
      'tags': tags.join(','), // ["iş","aile"] → "iş,aile"
      'audioPath': audioPath,
      'location': location,
      'weather': weather,
      'documentContent': documentContent,
    };
  }

  // Veritabanından gelen Map'i DiaryEntry'e çevir
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      mood: map['mood'] as String? ?? 'neutral',
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      audioPath: map['audioPath'] as String?,
      location: map['location'] as String?,
      weather: map['weather'] as String?,
      documentContent: map['documentContent'] as String?,
    );
  }

  // Mevcut girdiyi güncellemek için — sadece değişen alanları yaz
  DiaryEntry copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mood,
    List<String>? tags,
    String? audioPath,
    String? location,
    String? weather,
    String? documentContent,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      audioPath: audioPath ?? this.audioPath,
      location: location ?? this.location,
      weather: weather ?? this.weather,
      documentContent: documentContent ?? this.documentContent,
    );
  }
}
