import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';
import 'player_rating_screen.dart';

class SessionDetailsScreen extends StatefulWidget {
  final Session session;
  const SessionDetailsScreen({super.key, required this.session});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  late final FirebaseService _service;
  List<Player> _players = [];
  List<String> _attendingPlayers = [];
  bool _hasRatings = false;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _loadData();
  }

  Future<void> _loadData() async {
    final players = await _service.getPlayers();
    // Check if ratings already exist for this session
    final existing = await _service.getSessionRatings(widget.session.id!);
    final existingRatings = existing['ratings'] as Map<String, int>;

    if (mounted) {
      setState(() {
        _players = players;
        _attendingPlayers = widget.session.attendingPlayers;
        _hasRatings = existingRatings.isNotEmpty;
      });
    }
  }

  void _toggleAttendance(String playerId) {
    setState(() {
      if (_attendingPlayers.contains(playerId)) {
        _attendingPlayers.remove(playerId);
      } else {
        _attendingPlayers.add(playerId);
      }
    });
  }

  Future<void> _saveAttendance() async {
    await _service.updateSessionAttendance(widget.session.id!, _attendingPlayers);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Attendance saved!')]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _openRatingScreen() {
    final attendingPlayerObjects = _players
        .where((p) => _attendingPlayers.contains(p.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerRatingScreen(
          session: widget.session,
          attendingPlayers: attendingPlayerObjects,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        actions: [
          // Rate Players button in AppBar
          TextButton.icon(
            onPressed: _attendingPlayers.isEmpty ? null : _openRatingScreen,
            icon: Icon(
              Icons.star_rounded,
              color: _hasRatings ? Colors.amber : Colors.white,
            ),
            label: Text(
              _hasRatings ? 'Ratings ✓' : 'Rate Players',
              style: TextStyle(
                color: _hasRatings ? Colors.amber : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Session Info Card
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isDark ? const BorderSide(color: Colors.white12) : BorderSide.none,
            ),
            elevation: isDark ? 0 : 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: isDark ? const Color(0xFF00E676) : const Color(0xFF004D40), size: 20),
                      const SizedBox(width: 8),
                      Text('Session Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.calendar_today, 'Date', widget.session.date, isDark),
                  _buildInfoRow(Icons.access_time, 'Time', widget.session.timeStart, isDark),
                  _buildInfoRow(Icons.stadium, 'Stadium', widget.session.stadium, isDark),
                  _buildInfoRow(Icons.timer, 'Duration', widget.session.duration, isDark),
                ],
              ),
            ),
          ),

          // Attendance count header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance (${_attendingPlayers.length}/${_players.length})',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF00E676) : const Color(0xFF004D40)),
                ),
                // Rating quick-action chip
                if (_hasRatings)
                  Chip(
                    avatar: const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    label: const Text('Rated', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.amber.withOpacity(0.15),
                    labelStyle: const TextStyle(color: Colors.amber),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ),

          // Player List
          Expanded(
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (ctx, index) {
                final player = _players[index];
                final isAttending = _attendingPlayers.contains(player.id);
                return CheckboxListTile(
                  value: isAttending,
                  onChanged: (_) => _toggleAttendance(player.id!),
                  activeColor: const Color(0xFF004D40),
                  title: Text(
                    player.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '${player.position} — #${player.shirtNumber}',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 12),
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: isAttending
                        ? const Color(0xFF004D40)
                        : (isDark ? Colors.white12 : Colors.grey.shade200),
                    child: Text(
                      '#${player.shirtNumber}',
                      style: TextStyle(
                        color: isAttending ? Colors.white : (isDark ? Colors.white54 : Colors.grey),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                // Rate Players button
                if (_attendingPlayers.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openRatingScreen,
                      icon: Icon(_hasRatings ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber),
                      label: Text(
                        _hasRatings ? '⭐  Edit Player Ratings' : '⭐  Rate Player Performances',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: const BorderSide(color: Colors.amber, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveAttendance,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: isDark ? Colors.white38 : Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}