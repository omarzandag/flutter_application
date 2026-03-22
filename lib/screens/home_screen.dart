import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/player.dart';
import '../models/session.dart';
import 'players_screen.dart';
import 'sessions_screen.dart';
import 'formation_screen.dart';
import 'settings_screen.dart';
import 'match_engine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FirebaseService _service;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
  }
  
  // Data lists
  List<Player> _players = [];
  List<Session> _sessions = [];
  Session? _nextSession;
  List<Player> _topPerformers = [];
  
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This runs every time the screen is resumed (e.g., after adding a player)
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final players = await _service.getPlayers();
      final sessions = await _service.getSessions();
      
      if (mounted) {
        setState(() {
          _players = players;
          _sessions = sessions;
          
          // Sort to find the closest upcoming session
          final futureSessions = sessions
              .where((s) => !s.isPassed)
              .toList()
            ..sort((a, b) {
              final da = a.scheduledDateTime;
              final db = b.scheduledDateTime;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });

          _nextSession = futureSessions.isNotEmpty ? futureSessions.first : null;
          
          // Pre-calculate Top Performers
          final sortedPlayers = List<Player>.from(players)..sort((a, b) => (b.goals + b.assists).compareTo(a.goals + a.assists));
          _topPerformers = sortedPlayers.take(3).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    
    // Helper to return and reset Nav Bar
    void navAndReset(Widget screen) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
        // Reset to Home (0) when popped back
        if (mounted) {
          setState(() => _selectedIndex = 0);
          _loadData();
        }
      });
    }

    switch (index) {
      case 1:
        navAndReset(const PlayersScreen());
        break;
      case 2:
        navAndReset(const SessionsScreen());
        break;
      case 3:
        navAndReset(const FormationScreen());
        break;
      case 4:
        navAndReset(const SettingsScreen());
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    int available = _players.where((p) => p.status == 'Available').length;
    int absent = _players.where((p) => p.status == 'Absent' || p.status == 'Injured').length;
    int total = _players.length;

    final user = FirebaseAuth.instance.currentUser;
    final coachName = user?.email?.split('@').first ?? 'Coach';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Team Manager ⚽', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Welcome, $coachName', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNextTrainingCard(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildPlayersStats(available, absent),
                    const SizedBox(height: 20),
                    _buildSquadReadiness(available, total),
                    const SizedBox(height: 20),
                    _buildCoachMessage(),
                    const SizedBox(height: 20),
                    _buildTopPerformers(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF004D40),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Players'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Formation'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNextTrainingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00251A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF004D40).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NEXT MATCH / TRAINING', style: TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const Icon(Icons.sports_soccer, color: Color(0xFF00E676), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nextSession != null ? _nextSession!.title : 'No Upcoming Events',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_nextSession != null) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text('${_nextSession!.date} - ${_nextSession!.timeStart}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text('${_nextSession!.stadium}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: const Color(0xFF004D40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen())).then((_) => _loadData()),
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Creative Feature: Squad Readiness Meter ───────────────────────────
  Widget _buildSquadReadiness(int available, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = total == 0 ? 0.0 : (available / total).clamp(0.0, 1.0);
    final pctInt = (pct * 100).round();

    Color barColor;
    String status;
    IconData statusIcon;
    if (pct >= 0.8) {
      barColor = const Color(0xFF00E676);
      status = 'Full Strength';
      statusIcon = Icons.bolt;
    } else if (pct >= 0.6) {
      barColor = Colors.amber;
      status = 'Good Shape';
      statusIcon = Icons.thumb_up;
    } else if (pct >= 0.4) {
      barColor = Colors.orange;
      status = 'Reduced Squad';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      barColor = Colors.redAccent;
      status = 'Critical Level';
      statusIcon = Icons.crisis_alert;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: barColor.withOpacity(0.35), width: 1.5),
        boxShadow: [BoxShadow(color: barColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(statusIcon, color: barColor, size: 20),
                const SizedBox(width: 8),
                Text('Squad Readiness', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
              ]),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: barColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: barColor, fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 12,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$pctInt%',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$available available of $total total players',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  // A creative motivational section
  Widget _buildCoachMessage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coach\'s Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                const SizedBox(height: 4),
                Text('"Hard work beats talent when talent doesn\'t work hard. Let\'s go!"', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final squadColor = isDark ? const Color(0xFF00E676) : const Color(0xFF004D40);
    final titleColor = isDark ? const Color(0xFF00E676) : const Color(0xFF004D40);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildActionButton('Match Engine', Icons.timer, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchEngineScreen())).then((_) => _loadData())),
            _buildActionButton('Squad', Icons.people_alt, squadColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayersScreen())).then((_) => _loadData())),
            _buildActionButton('Training', Icons.fitness_center, Colors.orange[700]!, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen())).then((_) { setState(() => _selectedIndex = 0); _loadData(); })),
            _buildActionButton('Tactics', Icons.sports_soccer, isDark ? Colors.purpleAccent : Colors.purple[700]!, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormationScreen())).then((_) { setState(() => _selectedIndex = 0); _loadData(); })),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color themeColor, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: themeColor.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: themeColor, size: 28),
             ),
             const SizedBox(height: 8), 
             Text(label, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14))
          ]
        ),
      ),
    );
  }

  Widget _buildPlayersStats(int available, int absent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Availability Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildStatBox('Available', available, const Color(0xFF00E676), Icons.check_circle)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatBox('Absent/Injured', absent, Colors.redAccent, Icons.cancel)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, int value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildTopPerformers() {
    if (_topPerformers.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Top Performers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF00E676) : const Color(0xFF004D40))),
        const SizedBox(height: 12),
        ..._topPerformers.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
            borderRadius: BorderRadius.circular(12), 
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(isDark ? 0.0 : 0.1), blurRadius: 4, offset: const Offset(0, 2))],
            border: Border.all(color: Colors.green.withOpacity(isDark ? 0.3 : 0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF004D40),
                foregroundColor: Colors.white,
                child: Text('${p.shirtNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                    Text(p.position, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('⚽ ${p.goals}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF00E676) : const Color(0xFF004D40))),
                  const SizedBox(height: 4),
                  Text('👟 ${p.assists}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }
}