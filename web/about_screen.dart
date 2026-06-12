import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_helper.dart';
import '../models/event.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Live stats from DB
  int _totalEvents = 0;
  int _favoritesCount = 0;
  Map<String, int> _categoryCounts = {};
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final events = await DatabaseHelper.instance.readAllEvents();
    final counts = <String, int>{};
    int favs = 0;
    for (final e in events) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
      if (e.isFavorite) favs++;
    }
    if (mounted) {
      setState(() {
        _totalEvents = events.length;
        _favoritesCount = favs;
        _categoryCounts = counts;
        _statsLoaded = true;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('ABOUT')),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: RefreshIndicator(
            color: const Color(0xFFD4AF37),
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Profile hero ─────────────────────────────────────────
                  _buildProfileHero(),

                  // ── Live stats grid ──────────────────────────────────────
                  _buildSectionHeader('YOUR LIBRARY'),
                  _buildStatsGrid(),

                  // ── Category breakdown ───────────────────────────────────
                  if (_statsLoaded && _categoryCounts.isNotEmpty) ...[
                    _buildSectionHeader('BY CATEGORY'),
                    _buildCategoryBreakdown(),
                  ],

                  // ── How it works ─────────────────────────────────────────
                  _buildSectionHeader('HOW IT WORKS'),
                  _buildHowItWorks(),

                  // ── Tech stack ───────────────────────────────────────────
                  _buildSectionHeader('BUILT WITH'),
                  _buildTechStack(),

                  // ── Footer ───────────────────────────────────────────────
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Profile hero ─────────────────────────────────────────────────────────────
  Widget _buildProfileHero() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        children: [
          // Avatar ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFFD4AF37),
                  Color(0xFFF5E27A),
                  Color(0xFFD4AF37),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF121212),
              ),
              child: const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFF1E1E1E),
                child: Text(
                  'B',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD4AF37),
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bawan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mobile Technology Architecture',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 20),
          // GitHub button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchURL(
                'https://github.com/bawanexpert/local_event_finder.git',
              ),
              icon: const Icon(Icons.code_rounded, size: 18),
              label: const Text('View Source on GitHub'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4AF37),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: const Color(0xFF2C2C2C))),
        ],
      ),
    );
  }

  // ── Stats grid ────────────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    final stats = [
      _StatItem(
        icon: Icons.event_rounded,
        label: 'Total Events',
        value: _statsLoaded ? '$_totalEvents' : '—',
        color: const Color(0xFF3B82F6),
      ),
      _StatItem(
        icon: Icons.bookmark_rounded,
        label: 'Saved',
        value: _statsLoaded ? '$_favoritesCount' : '—',
        color: const Color(0xFFD4AF37),
      ),
      _StatItem(
        icon: Icons.category_rounded,
        label: 'Categories',
        value: _statsLoaded ? '${_categoryCounts.length}' : '—',
        color: const Color(0xFF8B5CF6),
      ),
      _StatItem(
        icon: Icons.explore_rounded,
        label: 'Discover',
        value: _statsLoaded ? (_totalEvents - _favoritesCount).toString() : '—',
        color: const Color(0xFF10B981),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: stats.map((s) => _buildStatCard(s)).toList(),
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  style: TextStyle(
                    color: stat.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  stat.label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category breakdown ────────────────────────────────────────────────────────
  Widget _buildCategoryBreakdown() {
    final total = _totalEvents > 0 ? _totalEvents : 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Column(
          children: _categoryCounts.entries.map((entry) {
            final meta = categoryMeta(entry.key);
            final pct = entry.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(meta.icon, size: 14, color: meta.color),
                      const SizedBox(width: 6),
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${entry.value} event${entry.value == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: meta.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF2C2C2C),
                      valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── How it works ──────────────────────────────────────────────────────────────
  Widget _buildHowItWorks() {
    final steps = [
      (
        icon: Icons.add_circle_outline_rounded,
        color: const Color(0xFF10B981),
        title: 'Add an event',
        desc:
            'Tap + on the Events tab. Fill in the title, date, time, location, and category.',
      ),
      (
        icon: Icons.swipe_rounded,
        color: const Color(0xFF3B82F6),
        title: 'Swipe to manage',
        desc:
            'Swipe right on any card to edit it. Swipe left to delete with confirmation.',
      ),
      (
        icon: Icons.bookmark_add_outlined,
        color: const Color(0xFFD4AF37),
        title: 'Save favorites',
        desc: 'Open an event and tap the bookmark icon to mark it as saved.',
      ),
      (
        icon: Icons.filter_list_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'Filter and sort',
        desc:
            'Use the category chips to filter, and the sort icon to order by date or title.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: Column(
          children: List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: step.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(step.icon, color: step.color, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              step.desc,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    indent: 66,
                    color: Color(0xFF222222),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Tech stack ────────────────────────────────────────────────────────────────
  Widget _buildTechStack() {
    final stack = [
      (label: 'Flutter', sub: 'UI framework', color: const Color(0xFF54C5F8)),
      (label: 'Dart', sub: 'Language', color: const Color(0xFF00B4AB)),
      (
        label: 'SQLite',
        sub: 'Local database via sqflite',
        color: const Color(0xFF8B5CF6),
      ),
      (
        label: 'Material 3',
        sub: 'Design system',
        color: const Color(0xFF3B82F6),
      ),
      (
        label: 'url_launcher',
        sub: 'External links',
        color: const Color(0xFFD4AF37),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: stack.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: item.color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.sub,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      child: Column(
        children: [
          Container(height: 1, color: const Color(0xFF2C2C2C)),
          const SizedBox(height: 20),
          Text(
            '© 2026 Local Event Finder',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0  ·  Built with Flutter',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
