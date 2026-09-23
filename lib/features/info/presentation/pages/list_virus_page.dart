import 'package:flutter/material.dart';
import '../../data/datasources/virus_local_data.dart';
import '../../data/models/virus_model.dart';
import 'detail_virus_page.dart';

class ListVirusPage extends StatefulWidget {
  const ListVirusPage({super.key});

  @override
  State<ListVirusPage> createState() => _ListVirusPageState();
}

class _ListVirusPageState extends State<ListVirusPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  List<Virus> _filtered(List<Virus> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((v) {
      return v.name.toLowerCase().contains(q) ||
          v.type.toLowerCase().contains(q) ||
          v.explanation.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final viruses = _filtered(VirusLocalData.viruses);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Sticky Header ──────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFFF4F8F5),
              elevation: 0,
              automaticallyImplyLeading: false,
              expandedHeight: 130,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Explore Types',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1C3D1E),
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                '${viruses.length} virus types',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF7A9E82),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _SearchBar(
                    controller: _searchCtrl,
                    hint: 'Search virus type...',
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () => setState(() {
                      _searchCtrl.clear();
                      _query = '';
                    }),
                  ),
                ),
              ),
            ),

            // ── Empty state ────────────────────────────────────────────
            if (viruses.isEmpty)
              const SliverFillRemaining(
                child: _EmptyState(message: 'No virus type found'),
              )
            else
              // ── Grid ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final virus = viruses[index];
                      return _VirusGridCard(
                        virus: virus,
                        index: index,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailVirusPage(virus: virus),
                          ),
                        ),
                      );
                    },
                    childCount: viruses.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Virus Grid Card ──────────────────────────────────────────────────────────
class _VirusGridCard extends StatelessWidget {
  final Virus virus;
  final VoidCallback onTap;
  final int index;

  const _VirusGridCard({
    required this.virus,
    required this.onTap,
    required this.index,
  });

  // Subtle accent colors cycling through cards
  static const List<Color> _accents = [
    Color(0xFFE8F5E9),
    Color(0xFFE3F2E6),
    Color(0xFFEAF4EA),
    Color(0xFFE6F3EC),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _accents[index % _accents.length];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDE9), width: 1),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  color: bg,
                  child: Image.asset(
                    virus.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.bug_report_rounded,
                      color: Color(0xFF3A7D44),
                      size: 26,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                virus.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3D1E),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      virus.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A9E82),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Color(0xFF7A9E82),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared: Search Bar ───────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8DE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF7A9E82), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFAAC0AD),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EBE1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF4A7A52),
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared: Circle Icon Button ───────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDDE8DE), width: 1),
          ),
          child: Center(
            child: Icon(icon, size: 16, color: const Color(0xFF1C3D1E)),
          ),
        ),
      ),
    );
  }
}

// ── Shared: Empty State ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF3A7D44),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C3D1E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different keyword',
            style: TextStyle(fontSize: 13, color: Color(0xFF7A9E82)),
          ),
        ],
      ),
    );
  }
}