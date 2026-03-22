import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';

class TransferHubScreen extends StatefulWidget {
  const TransferHubScreen({super.key});

  @override
  State<TransferHubScreen> createState() => _TransferHubScreenState();
}

class _TransferHubScreenState extends State<TransferHubScreen> {
  late final FirebaseService _service;
  final List<Map<String, dynamic>> _news = [
    {'title': 'Rising Star Spotted!', 'content': 'Scouts are raving about a young talent in the local league.', 'icon': Icons.star},
    {'title': 'Transfer Window Open', 'content': 'It\'s time to bolster the squad for the upcoming season.', 'icon': Icons.door_front_door},
    {'title': 'Budget Increased', 'content': 'The board has allocated more funds for new signings.', 'icon': Icons.payments},
  ];

  late List<Player> _scoutedPlayers;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _generateScoutedPlayers();
  }

  void _generateScoutedPlayers() {
    final firstNames = ['Marco', 'Luka', 'Kevin', 'Erling', 'Kylian', 'Jude', 'Phil', 'Bukayo', 'Pedri', 'Gavi'];
    final lastNames = ['Silva', 'Modric', 'De Bruyne', 'Haaland', 'Mbappe', 'Bellingham', 'Foden', 'Saka', 'Gonzalez', 'Paez'];
    final positions = ['Forward', 'Midfielder', 'Defender', 'Goalkeeper'];
    
    final random = Random();
    _scoutedPlayers = List.generate(5, (index) {
      return Player(
        fullName: '${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}',
        age: 18 + random.nextInt(10),
        shirtNumber: 1 + random.nextInt(99),
        position: positions[random.nextInt(positions.length)],
        team: 'Free Agent',
        status: 'Available',
      );
    });
  }

  Future<void> _signPlayer(Player player) async {
    setState(() => _isSigning = true);
    try {
      await _service.addPlayer(player);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${player.fullName} signed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _scoutedPlayers.remove(player);
          _isSigning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing player: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Hub 📢'),
        backgroundColor: isDark ? const Color(0xFF00251A) : const Color(0xFF004D40),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Transfer News', Icons.newspaper),
              const SizedBox(height: 12),
              _buildNewsCarousel(),
              const SizedBox(height: 24),
              _buildSectionTitle('Scouted Talents', Icons.search),
              const SizedBox(height: 12),
              if (_scoutedPlayers.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No more players to scout today.', style: TextStyle(color: Colors.grey)),
                ))
              else
                ..._scoutedPlayers.map((p) => _buildPlayerCard(p)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF004D40),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCarousel() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _news.length,
        itemBuilder: (context, index) {
          final item = _news[index];
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)] 
                  : [Colors.white, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(item['icon'] as IconData, color: Colors.orange, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(item['content'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    // Mocking some extra scout data
    final rating = 70 + Random().nextInt(20);
    final potential = rating + Random().nextInt(10);
    final marketValue = (rating * rating * 1000).toString().substring(0, 2) + "M";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(player.fullName[0], style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('${player.age} years • ${player.position}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rating: $rating', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text('Pot: $potential', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Market Value', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  Text('€$marketValue', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isSigning ? null : () => _signPlayer(player),
                icon: const Icon(Icons.add_task),
                label: const Text('Sign Player'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
