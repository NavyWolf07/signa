import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/diary_entry.dart';
import '../../domain/entry_notifier.dart';
import '../widgets/calendar_view.dart';
import '../widgets/entry_card.dart';
import '../widgets/statistics_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedMood = 'all';
  bool _isSearching = false;
  int _currentIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entryNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                child: child,
              ),
            );
          },
          child: _isSearching
              ? _SearchField(
                  key: const ValueKey('search'),
                  controller: _searchController,
                  onChanged: (query) {
                    ref.read(entryNotifierProvider.notifier).search(query);
                  },
                )
              : Text(
                  'Günlüğüm',
                  key: const ValueKey('title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              tooltip: _isSearching ? 'Aramayı kapat' : 'Ara',
              onPressed: _toggleSearch,
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
            onPressed: () => context.pushNamed('settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildListTab(entriesAsync, theme),
          entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Hata: $error')),
            data: (entries) => CalendarView(entries: entries),
          ),
          entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Hata: $error')),
            data: (entries) => StatisticsView(entries: entries),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            if (index != 0 && _isSearching) {
              _isSearching = false;
              _clearSearch();
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Liste',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'İstatistik',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'home_fab',
              onPressed: () => context.pushNamed('editor-new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Anı'),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            )
          : null,
    );
  }

  Widget _buildListTab(AsyncValue<List<DiaryEntry>> entriesAsync, ThemeData theme) {
    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Bir hata oluştu: $error')),
      data: (entries) {
        final filteredEntries = _selectedMood == 'all'
            ? entries
            : entries.where((entry) => entry.mood == _selectedMood).toList();

        return Column(
          children: [
            _HeroSection(
              isSearching: _isSearching,
              query: _searchController.text,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildMoodFilter(theme, entries),
            ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                key: ValueKey(
                  'scroll-${filteredEntries.length}-$_selectedMood-${_searchController.text}',
                ),
                slivers: [
                  if (filteredEntries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        key: ValueKey('empty-$_selectedMood-${_searchController.text}'),
                        isSearching: _isSearching,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = filteredEntries[index];
                            return EntryCard(
                              entry: entry,
                              onTap: () => context.pushNamed(
                                'editor-edit',
                                pathParameters: {'id': entry.id.toString()},
                              ),
                              onDelete: () => ref
                                  .read(entryNotifierProvider.notifier)
                                  .deleteEntry(entry.id!),
                            );
                          },
                          childCount: filteredEntries.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodFilter(ThemeData theme, List<DiaryEntry> entries) {
    final moods = [
      {'value': 'all', 'emoji': '🌟', 'label': 'Hepsi'},
      {'value': 'happy', 'emoji': '😊', 'label': 'Mutlu'},
      {'value': 'neutral', 'emoji': '😐', 'label': 'Nötr'},
      {'value': 'sad', 'emoji': '😢', 'label': 'Üzgün'},
      {'value': 'excited', 'emoji': '🤩', 'label': 'Heyecanlı'},
      {'value': 'angry', 'emoji': '😠', 'label': 'Sinirli'},
      {'value': 'tired', 'emoji': '😴', 'label': 'Yorgun'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ruh haline göre filtrele',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: moods.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final mood = moods[index];
                final moodValue = mood['value']!;
                final isSelected = _selectedMood == moodValue;
                final count = moodValue == 'all'
                    ? entries.length
                    : entries.where((entry) => entry.mood == moodValue).length;
                final accent = _moodColor(moodValue, theme);

                return AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  scale: isSelected ? 1 : 0.98,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() => _selectedMood = moodValue);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color.alphaBlend(
                                accent.withValues(alpha: 0.14),
                                theme.colorScheme.surface,
                              )
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          width: isSelected ? 1.6 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.16),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood['emoji']!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mood['label']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(entryNotifierProvider.notifier).search('');
  }

  Color _moodColor(String mood, ThemeData theme) {
    return theme.colorScheme.primary;
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Başlık ya da içerik ara...',
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        border: InputBorder.none,
        filled: false,
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.isSearching,
    required this.query,
  });

  final bool isSearching;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (isSearching) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Günlüğüne hoş geldin',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMMM yyyy, EEEE', 'tr').format(now),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_stories_rounded,
            size: 40,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    super.key,
    required this.isSearching,
  });

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearching ? Icons.search_off_rounded : Icons.auto_stories_outlined,
                  size: 34,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isSearching ? 'Sonuç bulunamadı' : 'İlk sayfayı açmaya hazırsın',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Aradığın ifadeyi biraz değiştirerek tekrar deneyebilirsin.'
                    : 'Henüz günlük girdisi yok. Aşağıdaki butonla yeni bir anı ekleyebilirsin.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


