import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/firebase_service.dart';
import 'session_details_screen.dart';
import 'add_session_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late final FirebaseService _service;
  List<Session> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _service.getSessions();
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          final upcoming = sessions.where((s) => !s.isPassed).toList()
            ..sort((a, b) => a.scheduledDateTime?.compareTo(b.scheduledDateTime ?? now) ?? 0);
          final past = sessions.where((s) => s.isPassed).toList()
            ..sort((a, b) => b.scheduledDateTime?.compareTo(a.scheduledDateTime ?? now) ?? 0);
          
          _sessions = [...upcoming, ...past];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSessionScreen()));
              _loadSessions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('No sessions scheduled'))
              : ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (ctx, index) {
                    final session = _sessions[index];
                    return _buildSessionCard(session);
                  },
                ),
    );
  }

  Widget _buildSessionCard(Session session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPassed = session.isPassed;
    final themeColor = isPassed ? Colors.redAccent : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 1 : 3,
      shadowColor: isDark ? Colors.transparent : themeColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark 
          ? BorderSide(color: isPassed ? Colors.redAccent.withOpacity(0.5) : Colors.white24, width: 1) 
          : (isPassed ? const BorderSide(color: Colors.redAccent, width: 1) : BorderSide.none),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: themeColor.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(Icons.fitness_center, color: themeColor),
        ),
        title: Text(session.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isPassed ? Colors.redAccent[700] : null)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: isPassed ? Colors.redAccent.withOpacity(0.7) : Colors.grey),
                  const SizedBox(width: 4),
                  Text('${session.date} - ${session.timeStart}', style: TextStyle(color: isPassed ? Colors.redAccent.withOpacity(0.7) : Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: isPassed ? Colors.redAccent.withOpacity(0.7) : Colors.grey),
                  const SizedBox(width: 4),
                  Text('${session.playerCount} Players', style: TextStyle(color: isPassed ? Colors.redAccent.withOpacity(0.7) : Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailsScreen(session: session)));
          _loadSessions();
        },
      ),
    );
  }
}