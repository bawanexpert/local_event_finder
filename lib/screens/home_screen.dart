import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database_helper.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

// ── Sort options ─────────────────────────────────────────────────────────────
enum SortBy { newest, oldest, title }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<LocalEvent>> _eventsFuture;
  List<LocalEvent> _allEvents = [];
  String? _filterCategory; // null = show all
  SortBy _sortBy = SortBy.newest;

  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _refreshEvents();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = DatabaseHelper.instance.readAllEvents().then((events) {
        _allEvents = events;
        return events;
      });
    });
  }

  List<LocalEvent> _applyFilters(List<LocalEvent> events) {
    List<LocalEvent> result = List.from(events);
    if (_filterCategory != null) {
      result = result.where((e) => e.category == _filterCategory).toList();
    }
    switch (_sortBy) {
      case SortBy.newest:
        result.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      case SortBy.oldest:
        result.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
        break;
      case SortBy.title:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return result;
  }

  // Count events per category
  Map<String, int> _categoryCounts(List<LocalEvent> events) {
    final counts = <String, int>{};
    for (final e in events) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('LOCAL EVENTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () async {
              await showSearch(
                context: context,
                delegate: EventSearchDelegate(_allEvents, _refreshEvents),
              );
            },
          ),
          // Sort menu
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort_rounded, color: Color(0xFFD4AF37)),
            color: const Color(0xFF1E1E1E),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              _sortItem(
                SortBy.newest,
                'Newest First',
                Icons.arrow_downward_rounded,
              ),
              _sortItem(
                SortBy.oldest,
                'Oldest First',
                Icons.arrow_upward_rounded,
              ),
              _sortItem(SortBy.title, 'By Title', Icons.sort_by_alpha_rounded),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<LocalEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }
          final all = snapshot.data ?? [];
          final counts = _categoryCounts(all);
          final filtered = _applyFilters(all);

          return Column(
            children: [
              // ── Category filter row with count badges ──────────────────
              if (all.isNotEmpty) _buildFilterRow(counts),

              // ── Events list ────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(all.isEmpty)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _AnimatedEventCard(
                            event: filtered[index],
                            index: index,
                            onDelete: () async {
                              await DatabaseHelper.instance.delete(
                                filtered[index].id!,
                              );
                              _refreshEvents();
                            },
                            onEdit: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddEditScreen(event: filtered[index]),
                                ),
                              );
                              _refreshEvents();
                            },
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    event: filtered[index],
                                    onChanged: _refreshEvents,
                                  ),
                                ),
                              );
                              _refreshEvents();
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditScreen()),
            );
            _refreshEvents();
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'NEW EVENT',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<SortBy> _sortItem(SortBy val, String label, IconData icon) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _sortBy == val ? const Color(0xFFD4AF37) : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: _sortBy == val ? const Color(0xFFD4AF37) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(Map<String, int> counts) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            // "All" chip
            _FilterChip(
              label: 'All',
              count: _allEvents.length,
              icon: Icons.apps_rounded,
              color: const Color(0xFFD4AF37),
              selected: _filterCategory == null,
              onTap: () => setState(() => _filterCategory = null),
            ),
            const SizedBox(width: 8),
            ...kCategoryMeta.keys.map((cat) {
              final count = counts[cat] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              final meta = categoryMeta(cat);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: cat,
                  count: count,
                  icon: meta.icon,
                  color: meta.color,
                  selected: _filterCategory == cat,
                  onTap: () => setState(() => _filterCategory = cat),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noEvents) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noEvents ? Icons.event_busy_rounded : Icons.filter_list_off_rounded,
            size: 72,
            color: Colors.grey.shade800,
          ),
          const SizedBox(height: 16),
          Text(
            noEvents
                ? 'No events yet.\nTap + to add your first one.'
                : 'No events match this filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          if (!noEvents) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _filterCategory = null),
              child: const Text(
                'Clear filter',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated filter chip ──────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFF2C2C2C),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? color : Colors.grey,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(0.25)
                    : const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? color : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated event card with dual-swipe ──────────────────────────────────────
class _AnimatedEventCard extends StatefulWidget {
  final LocalEvent event;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _AnimatedEventCard({
    required this.event,
    required this.index,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  State<_AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<_AnimatedEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 60),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = categoryMeta(widget.event.category);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dismissible(
          key: Key('event_${widget.event.id}'),
          // Swipe right → Edit
          secondaryBackground: _swipeBg(
            alignment: Alignment.centerRight,
            color: Colors.red.shade900,
            icon: Icons.delete_sweep_rounded,
            label: 'Delete',
          ),
          background: _swipeBg(
            alignment: Alignment.centerLeft,
            color: const Color(0xFF1A3A5C),
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Edit
              widget.onEdit();
              return false; // don't actually dismiss
            } else {
              // Delete confirm
              return await _confirmDelete(context);
            }
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              widget.onDelete();
            }
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF252525)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    // Category color accent stripe
                    Container(width: 4, height: 88, color: meta.color),
                    const SizedBox(width: 16),
                    // Icon
                    Hero(
                      tag: 'event_icon_${widget.event.id}',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: meta.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: meta.color.withOpacity(0.25),
                          ),
                        ),
                        child: Icon(meta.icon, color: meta.color, size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.event.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.event.isFavorite)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.bookmark_rounded,
                                      size: 16,
                                      color: Color(0xFFD4AF37),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.event.date}  ·  ${widget.event.time}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.event.location,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBg({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Delete Event',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Remove "${widget.event.title}"? This cannot be undone.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Search Delegate ───────────────────────────────────────────────────────────
class EventSearchDelegate extends SearchDelegate {
  final List<LocalEvent> allEvents;
  final Function refreshCallback;

  EventSearchDelegate(this.allEvents, this.refreshCallback);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A)),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final hits = allEvents
        .where(
          (e) =>
              e.title.toLowerCase().contains(query.toLowerCase()) ||
              e.category.toLowerCase().contains(query.toLowerCase()) ||
              e.location.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    if (hits.isEmpty) {
      return const Center(
        child: Text(
          'No matching events.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: const Color(0xFF121212),
      child: ListView.builder(
        itemCount: hits.length,
        itemBuilder: (context, i) {
          final event = hits[i];
          final meta = categoryMeta(event.category);
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(meta.icon, color: meta.color, size: 20),
            ),
            title: Text(
              event.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '${event.category}  ·  ${event.date}',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: event.isFavorite
                ? const Icon(
                    Icons.bookmark_rounded,
                    color: Color(0xFFD4AF37),
                    size: 16,
                  )
                : null,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(
                    event: event,
                    onChanged: () => refreshCallback(),
                  ),
                ),
              );
              close(context, null);
            },
          );
        },
      ),
    );
  }
}
