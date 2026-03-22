import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/session.dart';
import '../services/firebase_service.dart';

class PlayerRatingScreen extends StatefulWidget {
  final Session session;
  final List<Player> attendingPlayers;

  const PlayerRatingScreen({
    super.key,
    required this.session,
    required this.attendingPlayers,
  });

  @override
  State<PlayerRatingScreen> createState() => _PlayerRatingScreenState();
}

class _PlayerRatingScreenState extends State<PlayerRatingScreen> {
  late final FirebaseService _service;
  Map<String, int> _ratings = {};    // playerId -> 1..5 stars
  Map<String, String> _notes = {};   // playerId -> coach note
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _loadExistingRatings();
  }

  Future<void> _loadExistingRatings() async {
    final existing = await _service.getSessionRatings(widget.session.id!);
    if (mounted) {
      setState(() {
        _ratings = existing['ratings'] ?? {};
        _notes = existing['notes'] ?? {};
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRatings() async {
    setState(() => _isSaving = true);
    await _service.saveSessionRatings(
      sessionId: widget.session.id!,
      ratings: _ratings,
      notes: _notes,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Ratings saved!')]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  double get _avgRating {
    if (_ratings.isEmpty) return 0.0;
    return _ratings.values.fold(0, (a, b) => a + b) / _ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Player Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.session.title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (!_isSaving)
            TextButton.icon(
              onPressed: _saveRatings,
              icon: const Icon(Icons.save, color: Color(0xFF00E676)),
              label: const Text('Save', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Banner
                if (_ratings.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF004D40), Color(0xFF00695C)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statPill('Rated', '${_ratings.length}/${widget.attendingPlayers.length}', Icons.people),
                        _divider(),
                        _statPill('Avg Rating', _avgRating.toStringAsFixed(1), Icons.star),
                        _divider(),
                        _statPill('Best', '${_topPlayer()?.split(' ').first ?? '—'}', Icons.emoji_events),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Player List
                Expanded(
                  child: widget.attendingPlayers.isEmpty
                      ? Center(
                          child: Text(
                            'No players attended this session.',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.attendingPlayers.length,
                          itemBuilder: (ctx, i) {
                            final player = widget.attendingPlayers[i];
                            return _buildPlayerRatingCard(player, isDark);
                          },
                        ),
                ),
                // Save button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveRatings,
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save All Ratings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerRatingCard(Player player, bool isDark) {
    final pid = player.id ?? '';
    final currentRating = _ratings[pid] ?? 0;
    final note = _notes[pid] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentRating > 0
              ? _starColor(currentRating).withOpacity(0.4)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: currentRating > 0 ? _starColor(currentRating).withOpacity(0.07) : Colors.transparent,
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player info + rating badge
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${player.shirtNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                    Text(player.position, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (currentRating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _starColor(currentRating).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _ratingLabel(currentRating),
                    style: TextStyle(color: _starColor(currentRating), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Star rating row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (starIndex) {
              final starValue = starIndex + 1;
              return GestureDetector(
                onTap: () => setState(() {
                  if (_ratings[pid] == starValue) {
                    _ratings.remove(pid); // toggle off
                  } else {
                    _ratings[pid] = starValue;
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    starValue <= currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: starValue <= currentRating ? _starColor(currentRating) : (isDark ? Colors.white24 : Colors.grey.shade300),
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          // Note field (expandable)
          const SizedBox(height: 10),
          TextField(
            controller: TextEditingController(text: note),
            onChanged: (v) => _notes[pid] = v,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Coach note (optional)…',
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              prefixIcon: Icon(Icons.notes, size: 18, color: isDark ? Colors.white30 : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  String? _topPlayer() {
    if (_ratings.isEmpty) return null;
    final topId = _ratings.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    try {
      return widget.attendingPlayers.firstWhere((p) => p.id == topId).fullName;
    } catch (_) {
      return null;
    }
  }

  Color _starColor(int rating) {
    if (rating >= 5) return const Color(0xFF00E676); // 5 = elite green
    if (rating >= 4) return Colors.amber;            // 4 = good gold
    if (rating == 3) return Colors.orange;           // 3 = average orange
    return Colors.redAccent;                         // 1-2 = poor red
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 5: return '⭐ Elite';
      case 4: return '👍 Good';
      case 3: return '😐 Average';
      case 2: return '⚠️ Poor';
      case 1: return '❌ Dreadful';
      default: return '';
    }
  }

  Widget _statPill(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white24);
}
