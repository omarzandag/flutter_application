import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late final FirebaseService _service;
  List<Player> _allPlayers = []; // All players from DB
  List<Player> _stadiumPlayers = []; // Players placed on stadium
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final players = await _service.getPlayers();
      if (mounted) {
        setState(() {
          _allPlayers = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // Add player to stadium at default position
  void _addPlayerToStadium(Player player) {
    setState(() {
      // Place at center-bottom by default
      _stadiumPlayers.add(Player(
        id: player.id,
        fullName: player.fullName,
        age: player.age,
        shirtNumber: player.shirtNumber,
        position: player.position,
        team: player.team,
        xPos: 150, // Default X
        yPos: 400, // Default Y
      ));
    });
    Navigator.pop(context); // Close the player list modal
  }

  // Show bottom sheet with player list
  void _showPlayerList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            AppBar(
              title: const Text("Select Player"),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                )
              ],
            ),
            Expanded(
              child: _allPlayers.isEmpty
                  ? const Center(child: Text("No players found. Add players first."))
                  : ListView.builder(
                      controller: controller,
                      itemCount: _allPlayers.length,
                      itemBuilder: (ctx, index) {
                        final p = _allPlayers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text("${p.shirtNumber}"),
                          ),
                          title: Text(p.fullName),
                          subtitle: Text("${p.position} • ${p.team}"),
                          onTap: () => _addPlayerToStadium(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Equipes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlayers,
          )
        ],
      ),
      body: Stack(
        children: [
          // Stadium Background
          Positioned.fill(
            child: Image.network(
              "https://img.freepik.com/free-vector/football-stadium-top-view_1077-16867.jpg",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.green[100]),
            ),
          ),

          // Floating + Button
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.green, size: 30),
              onPressed: _isLoading ? null : _showPlayerList,
            ),
          ),

          // Players on Stadium (only those added)
          ..._stadiumPlayers.map((player) => _buildDraggablePlayer(player)),

          // Empty State Hint
          if (_stadiumPlayers.isEmpty)
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Tap + to add players",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggablePlayer(Player player) {
    return Positioned(
      left: player.xPos,
      top: player.yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Update local position
            final index = _stadiumPlayers.indexWhere((p) => p.id == player.id);
            if (index != -1) {
              _stadiumPlayers[index].xPos += details.delta.dx;
              _stadiumPlayers[index].yPos += details.delta.dy;
            }
          });
          // Optional: Save to Firebase
          // _service.updatePlayerPosition(player.id!, player.xPos, player.yPos);
        },
        onLongPress: () {
          // Optional: Remove player from stadium
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Remove Player"),
              content: Text("Remove ${player.fullName} from stadium?"),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _stadiumPlayers.removeWhere((p) => p.id == player.id);
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("Yes", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[800],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${player.shirtNumber}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                player.fullName.split(' ').last, // Show last name only
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}