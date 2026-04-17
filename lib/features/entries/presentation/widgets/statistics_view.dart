import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/diary_entry.dart';

class StatisticsView extends StatelessWidget {
  final List<DiaryEntry> entries;

  const StatisticsView({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined, size: 72, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'İstatistikler için henüz veri yok.',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16),
            ),
          ],
        ),
      );
    }

    final totalEntries = entries.length;
    final currentStreak = _calculateStreak(entries);
    final moodCounts = _calculateMoodCounts(entries);
    final topTags = _calculateTopTags(entries);
    final insight = _getInsightMessage(moodCounts, totalEntries);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── İçgörü Bandı ──
          _AnimatedEntrance(
            index: 0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'İÇ GÖRÜ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Üst Kartlar: Toplam Girdi ve Streak ──
          _AnimatedEntrance(
            index: 1,
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Toplam Anı',
                    value: totalEntries.toString(),
                    icon: Icons.auto_stories_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Yazma Serisi',
                    value: '$currentStreak Gün',
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Pasta Grafiği: Ruh Hali ──
          _AnimatedEntrance(
            index: 2,
            child: Text(
              'Ruh Hali Dağılımı',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedEntrance(
            index: 3,
            child: _buildCardContainer(
              theme,
              child: moodCounts.isEmpty
                  ? const Center(child: Text('Ruh hali verisi bulunamadı.'))
                  : SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: 0.8 + (value * 0.2),
                                  child: Opacity(
                                    opacity: value,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 3,
                                        centerSpaceRadius: 35,
                                        startDegreeOffset: 180 * (1 - value), // spins in
                                        sections: _buildPieChartSections(moodCounts),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: moodCounts.entries.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getMoodColor(e.key),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_getMoodEmoji(e.key)} ${e.value}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 24),

          // ── Yatay İlerleme Çubukları: Popüler Etiketler ──
          _AnimatedEntrance(
            index: 4,
            child: Text(
              'En Çok Kullanılan Etiketler',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedEntrance(
            index: 5,
            child: _buildCardContainer(
              theme,
              child: topTags.isEmpty
                  ? const Text('Hiç etiket kullanılmamış.')
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: topTags.asMap().entries.map((entryMap) {
                        int index = entryMap.key;
                        var tagEntry = entryMap.value;
                        bool isFirst = index == 0;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: isFirst
                                ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#${index + 1}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isFirst
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tagEntry.key,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${tagEntry.value}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isFirst ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(theme.colorScheme.primary.withValues(alpha: 0.08), theme.colorScheme.surface),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(theme.colorScheme.primary.withValues(alpha: 0.08), theme.colorScheme.surface),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getInsightMessage(Map<String, int> moodCounts, int totalEntries) {
    if (totalEntries == 0) return "Henüz analiz edilecek verin yok.";
    
    // Find dominant mood
    String dominantMood = '';
    int maxCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantMood = mood;
      }
    });

    if (dominantMood.isEmpty) return "Duyguların oldukça dengeli görünüyor.";

    final p = ((maxCount / totalEntries) * 100).toInt();
    final label = _getMoodLabel(dominantMood).toLowerCase();
    
    if (dominantMood == 'happy' || dominantMood == 'excited') {
      return "Harika! Genelde kendini oldukça $label hissediyorsun (%$p).";
    } else if (dominantMood == 'sad' || dominantMood == 'tired') {
      return "Son zamanlarda genelde $label görünüyorsun (%$p). Kendine biraz daha zaman ayırabilirsin.";
    } else if (dominantMood == 'angry') {
      return "Kayıtlarının %$p kadarı sinirli. Seni yoran şeyleri günlüğe dökmek iyi gelebilir.";
    } else {
      return "Duygusal durumun çoğunlukla $label bir seyir izliyor (%$p).";
    }
  }

  int _calculateStreak(List<DiaryEntry> entries) {
    if (entries.isEmpty) return 0;
    
    final uniqueDays = entries.map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day)).toSet().toList();
    uniqueDays.sort((a, b) => b.compareTo(a));

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (!uniqueDays.contains(today) && !uniqueDays.contains(yesterday)) {
      return 0; // Ne bugün ne dün yazılmış
    }

    int streak = 0;
    DateTime currentCheck = uniqueDays.contains(today) ? today : yesterday;

    for (int i = 0; i < uniqueDays.length; i++) {
      if (uniqueDays.contains(currentCheck)) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, int> _calculateMoodCounts(List<DiaryEntry> entries) {
    final Map<String, int> counts = {};
    for (var entry in entries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    return counts;
  }

  List<MapEntry<String, int>> _calculateTopTags(List<DiaryEntry> entries) {
    final Map<String, int> tagCounts = {};
    for (var entry in entries) {
      for (var tag in entry.tags) {
        if (tag.trim().isNotEmpty) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }
    final sorted = tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList(); 
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> moodCounts) {
    return moodCounts.entries.map((e) {
      return PieChartSectionData(
        color: _getMoodColor(e.key),
        value: e.value.toDouble(),
        title: '${e.value}',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy': return const Color(0xFFE3B52B);
      case 'sad': return const Color(0xFF5E8BFF);
      case 'angry': return const Color(0xFFE45D5D);
      case 'excited': return const Color(0xFFFF8A3D);
      case 'tired': return const Color(0xFF7167D6);
      default: return const Color(0xFF7A8796);
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy': return '😊';
      case 'neutral': return '😐';
      case 'sad': return '😢';
      case 'excited': return '🤩';
      case 'angry': return '😠';
      case 'tired': return '😴';
      default: return '🌟';
    }
  }
  
  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'happy': return 'Mutlu';
      case 'neutral': return 'Nötr';
      case 'sad': return 'Üzgün';
      case 'excited': return 'Heyecanlı';
      case 'angry': return 'Sinirli';
      case 'tired': return 'Yorgun';
      default: return 'Belirsiz';
    }
  }
}

class _AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedEntrance({required this.child, required this.index});

  @override
  State<_AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<_AnimatedEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 150 + (widget.index * 100)), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _visible ? 1.0 : 0.0,
        child: widget.child,
      ),
    );
  }
}
