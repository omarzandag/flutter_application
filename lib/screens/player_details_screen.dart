import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';
import 'add_player_screen.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final Player player;
  const PlayerDetailsScreen({super.key, required this.player});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  late final FirebaseService _service;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
  }

  void _updateStatus(String newStatus) async {
    await _service.updatePlayerStatus(widget.player.id!, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      Navigator.pop(context);
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('✔', style: TextStyle(fontSize: 20)),
              title: const Text('Available'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus('Available');
              },
            ),
            ListTile(
              leading: const Text('❌', style: TextStyle(fontSize: 20)),
              title: const Text('Absent'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus('Absent');
              },
            ),
            ListTile(
              leading: const Text('⚠', style: TextStyle(fontSize: 20)),
              title: const Text('Injured'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus('Injured');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deletePlayer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text('Are you sure you want to delete ${widget.player.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deletePlayer(widget.player.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.player.fullName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF1B5E20),
                      child: Text('#${widget.player.shirtNumber}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.player.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildInfoRow('Position', widget.player.position),
                    _buildInfoRow('Age', '${widget.player.age}'),
                    _buildInfoRow('Team', widget.player.team),
                    _buildInfoRow('Status', widget.player.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    const Divider(),
                    _buildInfoRow('⚽ Goals', '${widget.player.goals}'),
                    _buildInfoRow('🎯 Assists', '${widget.player.assists}'),
                    _buildInfoRow('🟨 Yellow Cards', '${widget.player.yellowCards}'),
                    _buildInfoRow('🟥 Red Cards', '${widget.player.redCards}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPlayerScreen(player: widget.player)));
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deletePlayer,
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showStatusDialog,
              icon: const Icon(Icons.update),
              label: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}