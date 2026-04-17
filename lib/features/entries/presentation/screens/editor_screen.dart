import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:just_audio/just_audio.dart';
import '../../../audio/domain/audio_notifier.dart';

import '../../data/models/diary_entry.dart';
import '../../domain/entry_notifier.dart';
import '../../domain/location_weather_service.dart';
import 'package:geolocator/geolocator.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.entryId, this.initialDate});
  final int? entryId;
  final DateTime? initialDate;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _titleController = TextEditingController();
  late QuillController _quillController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final ValueNotifier<String?> _currentlyPlayingPath = ValueNotifier(null);
  final ValueNotifier<Duration> _currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _totalDuration = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  
  String _selectedMood = 'neutral';
  List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _isLoading = false;
  DiaryEntry? _existingEntry;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  
  String? _location;
  String? _weather;

  // Ruh hali seçenekleri
  final _moods = [
    {'value': 'happy', 'emoji': '😊', 'label': 'Mutlu'},
    {'value': 'neutral', 'emoji': '😐', 'label': 'Nötr'},
    {'value': 'sad', 'emoji': '😢', 'label': 'Üzgün'},
    {'value': 'excited', 'emoji': '🤩', 'label': 'Heyecanlı'},
    {'value': 'angry', 'emoji': '😠', 'label': 'Sinirli'},
    {'value': 'tired', 'emoji': '😴', 'label': 'Yorgun'},
  ];

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    
    // Ses geçmişini temizle (Eğer eski veya başka bir ekrandan kalmışsa sıfırlansın)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioNotifierProvider.notifier).reset();
    });
    
    _titleController.addListener(() => setState(() {}));
    
    // Ses oynatma takibi
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        _isPlaying.value = state.playing && state.processingState != ProcessingState.completed;
        if (state.processingState == ProcessingState.completed) {
          _currentlyPlayingPath.value = null;
          _currentPosition.value = Duration.zero;
          _isPlaying.value = false;
        }
      }
    });
    
    _audioPlayer.positionStream.listen((pos) {
      if (mounted && _isPlaying.value) {
        _currentPosition.value = pos;
      }
    });
    
    _audioPlayer.durationStream.listen((dur) {
      if (mounted) {
        _totalDuration.value = dur ?? Duration.zero;
      }
    });
    
    // Düzenleme modundaysa mevcut veriyi yükle
    if (widget.entryId != null) {
      _loadEntry();
    }
  }

  Future<void> _loadEntry() async {
    setState(() => _isLoading = true);
    final repository = ref.read(entryRepositoryProvider);
    final entry = await repository.getById(widget.entryId!);
    if (entry != null && mounted) {
      setState(() {
        _existingEntry = entry;
        _titleController.text = entry.title;

        // Eğer zengin metin JSON'u varsa onu yükle, yoksa düz metni kullan
        if (entry.documentContent != null &&
            entry.documentContent!.isNotEmpty) {
          try {
            final json = jsonDecode(entry.documentContent!);
            _quillController.document = Document.fromJson(json);
          } catch (_) {
            // JSON parse hatası olursa düz metin olarak yükle
            _quillController.document = Document()
              ..insert(0, entry.content);
          }
        } else {
          // Eski günlükler — düz metin olarak yükleme
          _quillController.document = Document()
            ..insert(0, entry.content);
        }

        _selectedMood = entry.mood;
        _tags = List.from(entry.tags);
        _location = entry.location;
        _weather = entry.weather;
        
        if (entry.audioPath != null && entry.audioPath!.isNotEmpty) {
          final paths = entry.audioPath!.split(';');
          // Build sonrasına bırakarak state güncellemesini garanti alıyoruz
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(audioNotifierProvider.notifier).setRecordedPaths(paths);
          });
        }
        
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLocationWeather() async {
    final service = ref.read(locationWeatherServiceProvider);

    try {
      final result = await service.fetchCurrentData();
      if (mounted && result != null) {
        setState(() {
          _location = result.location;
          _weather = result.weather;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('LOCATION_SERVICE_DISABLED')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konum Kapalı'),
            content: const Text(
                'Lütfen cihazınızın konum (GPS) servisini açıp tekrar deneyin.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      } else if (e.toString().contains('PERMISSION_DENIED_FOREVER')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konum İzni Gerekli'),
            content: const Text(
                'Anlık konumu ve hava durumunu ekleyebilmek için ayarlardan erişim izni vermeniz gerekiyor.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Geolocator.openAppSettings();
                },
                child: const Text('Ayarlara Git'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    // Bellek sızıntısını önlemek için controller'ları temizle
    _currentlyPlayingPath.dispose();
    _currentPosition.dispose();
    _totalDuration.dispose();
    _isPlaying.dispose();
    _titleController.dispose();
    _quillController.dispose();
    _tagController.dispose();
    _audioPlayer.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Başlık boşsa kaydetme
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir başlık girin.')));
      return;
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(entryNotifierProvider.notifier);

    // Zengin metin verisini JSON formatında al
    final documentJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );
    // Arama ve listeleme için düz metin halini de al
    final plainText = _quillController.document.toPlainText().trim();

    if (_existingEntry != null) {
      // Güncelleme modu
      await notifier.updateEntry(
        _existingEntry!.copyWith(
          title: _titleController.text.trim(),
          content: plainText,
          documentContent: documentJson,
          mood: _selectedMood,
          tags: _tags,
          updatedAt: DateTime.now(),
          audioPath: ref.read(audioNotifierProvider).recordedPaths.isNotEmpty ? ref.read(audioNotifierProvider).recordedPaths.join(';') : null,
          location: _location,
          weather: _weather,
        ),
      );
    } else {
      // Yeni girdi modu
      await notifier.addEntry(
        DiaryEntry(
          title: _titleController.text.trim(),
          content: plainText,
          documentContent: documentJson,
          createdAt: widget.initialDate ?? DateTime.now(),
          mood: _selectedMood,
          tags: _tags,
          audioPath: ref.read(audioNotifierProvider).recordedPaths.isNotEmpty ? ref.read(audioNotifierProvider).recordedPaths.join(';') : null,
          location: _location,
          weather: _weather,
        ),
      );
    }

    if (mounted) {
      context.pop();
    }
  }

  void _onBackPressed() {
    // Kullanıcı bir şeyler yazdıysa uyar
    final hasContent = _quillController.document.toPlainText().trim().isNotEmpty;
    if (_titleController.text.isNotEmpty || hasContent) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Değişiklikler kaydedilmeyecek'),
          content: const Text(
            'Yazdıklarınız kaydedilmeyecek. Çıkmak istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Devam Et'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Çık'),
            ),
          ],
        ),
      );
    } else {
      // Hiçbir şey yazılmadıysa direkt çık
      context.pop();
    }
  }



  Widget _buildAudioSection() {
    return Consumer(
      builder: (context, ref, child) {
        final audioState = ref.watch(audioNotifierProvider);
        final audioNotifier = ref.read(audioNotifierProvider.notifier);
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- ÜST: KAYIT BÖLGESİ ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                constraints: const BoxConstraints(minHeight: 120),
                alignment: Alignment.center,
                child: audioState.audioState == AudioState.recording
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. İptal / Sil Butonu
                          IconButton(
                            onPressed: audioNotifier.cancelRecording,
                            icon: const Icon(Icons.delete_outline_rounded, size: 28),
                            color: theme.colorScheme.error,
                          ),
                          
                          // 2. Sayaç
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(color: theme.colorScheme.error, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${audioState.recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(audioState.recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 3. Soldan Sağa Akan Ekolaizer
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: List.generate(audioState.amplitudeHistory.length, (index) {
                                    final amp = audioState.amplitudeHistory[index];
                                    final amplitude = (amp + 160) / 160;
                                    final height = 4.0 + (36 * amplitude);
                                    
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 100),
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      width: 4,
                                      height: height.clamp(4.0, 40.0),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: index == audioState.amplitudeHistory.length - 1 ? 1.0 : 0.4),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                          
                          // 4. Kaydet Butonu (WhatsApp'taki Gönder Tuşu gibi)
                          GestureDetector(
                            onTap: audioNotifier.stopRecording,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 54,
                              width: 54,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ],
                      )
                    : FilledButton.icon(
                        onPressed: audioNotifier.startRecording,
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('Yeni Ses Ekle'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
              ),
            ),
            
            // --- ALT: KAYDEDİLMİŞ SESLER LİSTESİ ---
            if (audioState.audioState != AudioState.recording && audioState.recordedPaths.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                "Kayıtlı Sesler",
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: audioState.recordedPaths.asMap().entries.map((entry) {
                      final audioIndex = entry.key;
                      final path = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.mic_none_rounded, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([_currentlyPlayingPath, _isPlaying, _currentPosition, _totalDuration]),
                                builder: (context, _) {
                                  final isThisPlaying = _currentlyPlayingPath.value == path;
                                  final playing = _isPlaying.value;
                                  
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: isThisPlaying
                                            ? Row(
                                                children: [
                                                  if (playing)
                                                    StreamBuilder(
                                                      stream: Stream.periodic(const Duration(milliseconds: 150)),
                                                      builder: (context, _) {
                                                        return Expanded(
                                                          child: SingleChildScrollView(
                                                            scrollDirection: Axis.horizontal,
                                                            reverse: true,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                              children: List.generate(20, (index) {
                                                                final randBase = (path.hashCode ^ index).abs();
                                                                final dynamicPart = playing ? (DateTime.now().millisecondsSinceEpoch % (10 + (index % 5) * 5)) : 0;
                                                                final height = 5.0 + (randBase % 25) + dynamicPart;
                                                                
                                                                final isPlayed = index < (20 * (_totalDuration.value.inMilliseconds > 0 ? _currentPosition.value.inMilliseconds / _totalDuration.value.inMilliseconds : 0.0));
                                                                
                                                                return AnimatedContainer(
                                                                  duration: const Duration(milliseconds: 150),
                                                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                                                  width: 3.0,
                                                                  height: height.toDouble().clamp(4.0, 32.0),
                                                                  decoration: BoxDecoration(
                                                                    color: isPlayed ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.3),
                                                                    borderRadius: BorderRadius.circular(2),
                                                                  ),
                                                                );
                                                              }),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "${_currentPosition.value.inMinutes}:${(_currentPosition.value.inSeconds % 60).toString().padLeft(2, '0')} / ${_totalDuration.value.inMinutes}:${(_totalDuration.value.inSeconds % 60).toString().padLeft(2, '0')}",
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                'Ses Kaydı ${audioIndex + 1}',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                      ),
                                      IconButton(
                                        icon: Icon(isThisPlaying && playing ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 28),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        color: theme.colorScheme.primary,
                                        onPressed: () async {
                                          if (isThisPlaying && playing) {
                                            await _audioPlayer.pause();
                                          } else {
                                            if (!isThisPlaying) {
                                              await _audioPlayer.setFilePath(path);
                                              _currentlyPlayingPath.value = path;
                                            }
                                            await _audioPlayer.play();
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () => audioNotifier.removeRecording(path),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            // Hata mesajı
            if (audioState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    audioState.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }



  String _moodEmoji(String mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'excited':
        return '🤩';
      case 'angry':
        return '😠';
      case 'tired':
        return '😴';
      default:
        return '😐';
    }
  }

  String _moodLabel(String mood) {
    switch (mood) {
      case 'happy':
        return 'Mutlu';
      case 'sad':
        return 'Üzgün';
      case 'excited':
        return 'Heyecanlı';
      case 'angry':
        return 'Sinirli';
      case 'tired':
        return 'Yorgun';
      default:
        return 'Nötr';
    }
  }



  Color _moodTintColor(String mood, ThemeData theme) {
    switch (mood) {
      case 'happy':
        return const Color(0xFFE4C75A);
      case 'sad':
        return const Color(0xFF6A8DFF);
      case 'excited':
        return const Color(0xFFFF8A3D);
      case 'angry':
        return const Color(0xFFE45C5C);
      case 'tired':
        return const Color(0xFF7A7ADB);
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasContent = _titleController.text.trim().isNotEmpty;

    // ── Defter renkleri — tamamen temadan türetiliyor ──
    final seedColor = theme.colorScheme.primary;

    // Sayfa arka planı — temin surfaceContainerLowest'ten türetilir
    final pageColor = Color.alphaBlend(
      seedColor.withValues(alpha: isDark ? 0.06 : 0.04),
      theme.colorScheme.surfaceContainerLowest,
    );

    // Sayfa çizgileri
    final pageLineColor = Color.alphaBlend(
      seedColor.withValues(alpha: isDark ? 0.12 : 0.10),
      theme.colorScheme.surfaceContainerHigh,
    );

    // Kenar (margin) çizgisi — tema primary'sinin soluk versiyonu
    final marginLineColor = Color.alphaBlend(
      seedColor.withValues(alpha: isDark ? 0.35 : 0.30),
      theme.colorScheme.outline,
    );

    // Başlık arka planı
    final headerBg = Color.alphaBlend(
      seedColor.withValues(alpha: isDark ? 0.10 : 0.06),
      theme.colorScheme.surfaceContainerLowest,
    );

    // Başlık altı çizgi
    final titleLineColor = Color.alphaBlend(
      seedColor.withValues(alpha: 0.5),
      theme.colorScheme.surface,
    );

    // Binder (cilt kenarı) rengi — temadan türetilen
    final binderColor = Color.alphaBlend(
      seedColor.withValues(alpha: isDark ? 0.15 : 0.08),
      theme.colorScheme.surfaceContainer,
    );

    final binderHoleColor = Color.alphaBlend(
      seedColor.withValues(alpha: isDark ? 0.20 : 0.12),
      theme.colorScheme.surfaceContainerHighest,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.entryId == null ? 'Yeni Girdi' : 'Düzenle',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _onBackPressed(),
          ),
          actions: [
            if (widget.entryId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FilledButton.tonalIcon(
                  onPressed: _isLoading ? null : _save,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Kaydet'),
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: widget.entryId != null
            ? null
            : AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: hasContent ? 1.0 : 0.0,
                child: FloatingActionButton.extended(
                  heroTag: 'editor_fab',
                  onPressed: _isLoading ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Genişleyebilir içerik ──
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                        // ── Üst başlık — AppBar'a yakın kısım ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                          color: headerBg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tarih satırı
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(_existingEntry?.createdAt ??
                                        widget.initialDate ??
                                        DateTime.now()),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Başlık alanı
                              TextField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'Başlık...',
                                  hintStyle: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                                    fontFamily: 'serif',
                                  ),
                                  border: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  fontFamily: 'serif',
                                  letterSpacing: -0.3,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ],
                          ),
                        ),

                        // Başlık altı altın çizgi
                        Container(height: 2, color: titleLineColor),

                        // ── Defter sayfası — zengin metin içerik alanı ──
                        Expanded(
                          child: Container(
                            color: pageColor,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Sol kenar — Cilt (binder) bölümü ──
                                SizedBox(
                                  width: 52,
                                  child: CustomPaint(
                                  painter: _BinderPainter(
                                    binderColor: binderColor,
                                    holeColor: binderHoleColor,
                                    marginLineColor: marginLineColor,
                                    pageColor: pageColor,
                                  ),
                                  child: const SizedBox(width: 52),
                                ),
                              ),

                              // ── İçerik — çizgili arka plan + QuillEditor ──
                              Expanded(
                                child: CustomPaint(
                                  painter: _LinedPaperPainter(
                                    lineColor: pageLineColor,
                                    lineHeight: 32,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8, 4, 20, 20,
                                    ),
                                    child: QuillEditor(
                                      controller: _quillController,
                                      focusNode: _editorFocusNode,
                                      scrollController:
                                          _editorScrollController,
                                      config: QuillEditorConfig(
                                        placeholder: 'Bugün neler oldu?',
                                        padding: EdgeInsets.zero,
                                        customStyles: DefaultStyles(
                                          paragraph: DefaultTextBlockStyle(
                                            TextStyle(
                                              fontSize: 15,
                                              color: theme
                                                  .colorScheme.onSurface,
                                              fontFamily: 'serif',
                                              height: 32 / 15,
                                            ),
                                            const HorizontalSpacing(0, 0),
                                            const VerticalSpacing(0, 0),
                                            const VerticalSpacing(0, 0),
                                            null,
                                          ),
                                          placeHolder: DefaultTextBlockStyle(
                                            TextStyle(
                                              fontSize: 15,
                                              color: theme
                                                  .colorScheme.onSurface
                                                  .withValues(alpha: 0.3),
                                              fontFamily: 'serif',
                                              height: 32 / 15,
                                            ),
                                            const HorizontalSpacing(0, 0),
                                            const VerticalSpacing(0, 0),
                                            const VerticalSpacing(0, 0),
                                            null,
                                          ),
                                          bold: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          italic: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),

                        // (Alt kartlar kaldırılıp Composer'a çekildi)

                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Yeni Aksiyon Çubuğu (Composer Bar) ──
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Composer Araçları
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ActionChip(
                                  avatar: Text(_moodEmoji(_selectedMood)),
                                  label: Text(_moodLabel(_selectedMood)),
                                  onPressed: () => _showMoodSelectorSheet(context, theme),
                                  backgroundColor: _moodTintColor(_selectedMood, theme).withValues(alpha: 0.15),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                const SizedBox(width: 8),
                                ActionChip(
                                  avatar: const Icon(Icons.tag_rounded, size: 16),
                                  label: Text(_tags.isEmpty ? 'Etiket' : '${_tags.length} Etiket'),
                                  onPressed: () => _showTagInputSheet(context, theme),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onLongPress: _location != null ? () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Konumu Sil'),
                                        content: const Text('Eklediğiniz konumu ve hava durumunu kaldırmak istiyor musunuz?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                                          TextButton(
                                            onPressed: () {
                                              setState(() { _location = null; _weather = null; });
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      )
                                    );
                                  } : null,
                                  child: ActionChip(
                                    avatar: const Icon(Icons.location_on_rounded, size: 16),
                                    label: Text(_location ?? 'Konum'),
                                    onPressed: _location == null ? _fetchLocationWeather : () {},
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ActionChip(
                                  avatar: Icon(ref.watch(audioNotifierProvider).audioState == AudioState.idle ? Icons.mic : Icons.mic_none, size: 16),
                                  label: const Text('Ses'),
                                  onPressed: () => _showAudioSheet(context, theme),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Quill Toolbar
                        QuillSimpleToolbar(
                          controller: _quillController,
                          config: const QuillSimpleToolbarConfig(
                            showBoldButton: true,
                            showItalicButton: true,
                            showUnderLineButton: true,
                            showStrikeThrough: false,
                            showColorButton: true,
                            showBackgroundColorButton: false,
                            showListBullets: true,
                            showListNumbers: true,
                            showListCheck: true,
                            showQuote: true,
                            showHeaderStyle: true,
                            showLink: false,
                            showCodeBlock: false,
                            showInlineCode: false,
                            showIndent: false,
                            showAlignmentButtons: false,
                            showDirection: false,
                            showSearchButton: false,
                            showSubscript: false,
                            showSuperscript: false,
                            showSmallButton: false,
                            showFontFamily: false,
                            showFontSize: false,
                            showClipboardCut: false,
                            showClipboardCopy: false,
                            showClipboardPaste: false,
                            showRedo: true,
                            showUndo: true,
                            showClearFormat: true,
                            multiRowsDisplay: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  void _showMoodSelectorSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Nasıl hissediyorsun?", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _moods.map((mood) {
                  final val = mood['value'] as String;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() => _selectedMood = val);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedMood == val ? _moodTintColor(val, theme).withValues(alpha: 0.2) : theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedMood == val ? _moodTintColor(val, theme) : Colors.transparent),
                      ),
                      child: Text('${_moodEmoji(val)} ${_moodLabel(val)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showTagInputSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Etiketler", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setSheetState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _tags.map((t) => Chip(
                          label: Text(t),
                          onDeleted: () {
                            setState(() => _tags.remove(t));
                            setSheetState(() {});
                          },
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: "Yeni etiket ekle (Enter'a bas)",
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty && !_tags.contains(val.trim())) {
                            setState(() { _tags.add(val.trim()); _tagController.clear(); });
                            setSheetState(() {});
                          }
                        },
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        );
      });
  }

  void _showAudioSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.55,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            children: [
              Text("Ses Kaydı", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Expanded(child: _buildAudioSection()),
            ],
          ),
        );
      },
    );
  }
}

// ── Çizgili defter kağıdı ──
class _LinedPaperPainter extends CustomPainter {
  final Color lineColor;
  final double lineHeight;

  const _LinedPaperPainter({required this.lineColor, required this.lineHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    // İçeriğin yüksekliği kadar çizgi çiz
    double y = lineHeight;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(_LinedPaperPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.lineHeight != lineHeight;
}

// ── Gelişmiş Cilt Kenarı (Binder) Painter ──
class _BinderPainter extends CustomPainter {
  final Color binderColor;
  final Color holeColor;
  final Color marginLineColor;
  final Color pageColor;

  const _BinderPainter({
    required this.binderColor,
    required this.holeColor,
    required this.marginLineColor,
    required this.pageColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Arka plan ──
    final bgPaint = Paint()..color = pageColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // ── Cilt kenar şeridi (sol tarafta soluk dikey bant) ──
    final binderStripPaint = Paint()..color = binderColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 16, size.height),
      binderStripPaint,
    );

    // ── Cilt dikişi — ince dikey çizgi ──
    final stitchPaint = Paint()
      ..color = marginLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Kesikli çizgi efekti
    double y = 4;
    while (y < size.height) {
      canvas.drawLine(Offset(14, y), Offset(14, y + 8), stitchPaint);
      y += 14;
    }

    // ── Delikler — spiral defter delikleri ──
    final holePaint = Paint()..color = holeColor;
    final holeOutlinePaint = Paint()
      ..color = marginLineColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Gradyan ring efekti
    const holeRadius = 5.0;
    const holeSpacing = 52.0;
    double holeY = 30;

    while (holeY < size.height) {
      // Delik gölgesi
      canvas.drawCircle(
        Offset(28, holeY + 1),
        holeRadius,
        Paint()..color = holeColor.withValues(alpha: 0.3),
      );
      // Delik
      canvas.drawCircle(Offset(28, holeY), holeRadius, holePaint);
      // Delik kenarı
      canvas.drawCircle(Offset(28, holeY), holeRadius, holeOutlinePaint);
      holeY += holeSpacing;
    }

    // ── Kırmızı kenar çizgisi — klasik defter ──
    final marginPaint = Paint()
      ..color = marginLineColor
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(size.width - 2, 0),
      Offset(size.width - 2, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(_BinderPainter oldDelegate) =>
      oldDelegate.binderColor != binderColor ||
      oldDelegate.holeColor != holeColor ||
      oldDelegate.marginLineColor != marginLineColor ||
      oldDelegate.pageColor != pageColor;
}
