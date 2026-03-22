import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';
import 'player_details_screen.dart';
import 'add_player_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late final FirebaseService _service;
  List<Player> _players = [];
  List<Player> _filteredPlayers = [];
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _loadPlayers();
    _searchCtrl.addListener(_filterPlayers);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final players = await _service.getPlayers();
      if (mounted) {
        setState(() {
          _players = players;
          _filteredPlayers = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _filterPlayers() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredPlayers = _players.where((p) => p.fullName.toLowerCase().contains(query) || p.position.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Players (${_players.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlayerScreen()));
              _loadPlayers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: '🔍 Search player...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : null,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.white,
              ),
            ),
          ),
          // Player List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlayers.isEmpty
                    ? const Center(child: Text('No players found'))
                    : ListView.builder(
                        itemCount: _filteredPlayers.length,
                        itemBuilder: (ctx, index) {
                          final player = _filteredPlayers[index];
                          return _buildPlayerCard(player);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    Color statusColor;
    String statusIcon;
    switch (player.status) {
      case 'Available':
        statusColor = Colors.green;
        statusIcon = '✔';
        break;
      case 'Absent':
        statusColor = Colors.red;
        statusIcon = '❌';
        break;
      case 'Injured':
        statusColor = Colors.orange;
        statusIcon = '⚠';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = '';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 1 : 3,
      shadowColor: isDark ? Colors.transparent : Theme.of(context).primaryColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide(color: Colors.white24, width: 1) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: Text('#${player.shirtNumber}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        title: Text(player.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.position, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: statusColor),
                  const SizedBox(width: 4),
                  Text('${player.status}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: player)));
          _loadPlayers();
        },
      ),
    );
  }
}