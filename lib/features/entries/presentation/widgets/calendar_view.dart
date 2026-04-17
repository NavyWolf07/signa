import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/diary_entry.dart';
import '../../domain/entry_notifier.dart';
import 'entry_card.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({
    super.key,
    required this.entries,
  });

  final List<DiaryEntry> entries;

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Belirli bir tarihteki kayıtları döndür
  List<DiaryEntry> _getEventsForDay(DateTime day) {
    return widget.entries.where((entry) {
      return isSameDay(entry.createdAt, day);
    }).toList();
  }

  int get _monthEntryCount {
    return widget.entries.where((e) => e.createdAt.year == _focusedDay.year && e.createdAt.month == _focusedDay.month).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedEntries = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
        // ── Kapsayıcı Üst Bilgi ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy', 'tr').format(_focusedDay),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Bu ay $_monthEntryCount kayıt',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Takvim ──
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: TableCalendar<DiaryEntry>(
              daysOfWeekHeight: 32, // Gün isimlerinin yarım çıkmasını önler
              locale: 'tr_TR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Ay',
            },
            eventLoader: _getEventsForDay,
            
            // Seçim değiştiğinde
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            
            // Stiller
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
              todayTextStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              weekendTextStyle: TextStyle(color: theme.colorScheme.error),
              outsideDaysVisible: false,
            ),
            
            // Özelleştirilmiş event marker'ları
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((entry) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            ),
          ),
        ),

        // ── Seçili Gün Başlığı ──
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_selectedDay ?? _focusedDay),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('d MMMM yyyy, EEEE', 'tr').format(_selectedDay ?? _focusedDay),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${selectedEntries.length} kayıt',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── İçerikler ──
        if (selectedEntries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Bu tarihte kayıt yok.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = selectedEntries[index];
                  return _AnimatedEntryListItem(
                    index: index,
                    key: ValueKey(entry.id),
                    child: EntryCard(
                      entry: entry,
                      onTap: () => context.pushNamed(
                        'editor-edit',
                        pathParameters: {'id': entry.id.toString()},
                      ),
                      onDelete: () => ref
                          .read(entryNotifierProvider.notifier)
                          .deleteEntry(entry.id!),
                    ),
                  );
                },
                childCount: selectedEntries.length,
              ),
            ),
          ),

        // ── Alt kısımdaki yüzen butonun listeyi örtmemesi için boşluk ──
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    ),
    // ── Ekle Butonu (Yüzen - Sabit) ──
    Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton.extended(
            key: ValueKey(isSameDay(_selectedDay, DateTime.now())),
            heroTag: 'calendar_fab',
            onPressed: () {
              context.pushNamed(
                'editor-new',
                extra: _selectedDay,
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              isSameDay(_selectedDay, DateTime.now())
                  ? 'Bugüne Yeni Kayıt Ekle'
                  : 'Seçili Güne Kayıt Ekle',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    ),
  ],
);
  }
}

class _AnimatedEntryListItem extends StatefulWidget {
  const _AnimatedEntryListItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedEntryListItem> createState() => _AnimatedEntryListItemState();
}

class _AnimatedEntryListItemState extends State<_AnimatedEntryListItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 30 * widget.index), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
