import 'dart:async';
import 'package:flutter/material.dart';

class MatchEngineScreen extends StatefulWidget {
  const MatchEngineScreen({super.key});

  @override
  State<MatchEngineScreen> createState() => _MatchEngineScreenState();
}

class _MatchEngineScreenState extends State<MatchEngineScreen> {
  Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;

  int _homeScore = 0;
  int _awayScore = 0;
  String _homeName = 'HOME';
  String _awayName = 'AWAY';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch.isRunning && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime() {
    final secs = _stopwatch.elapsedMilliseconds ~/ 1000;
    final minutes = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (secs % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _resetMatch() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _homeScore = 0;
      _awayScore = 0;
    });
  }

  void _editTeamName(bool isHome) {
    final ctrl = TextEditingController(text: isHome ? _homeName : _awayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHome ? 'Edit Home Team' : 'Edit Away Team'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Team Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (isHome) _homeName = ctrl.text.toUpperCase();
                else _awayName = ctrl.text.toUpperCase();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Match Engine ⏱️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Match',
            onPressed: _resetMatch,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Colors.black87],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Digital Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  _formatTime(),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                  ),
                ),
              ),

              // Scoreboard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildTeamColumn(isHome: true)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: _buildTeamColumn(isHome: false)),
                  ],
                ),
              ),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_stopwatch.isRunning)
                    _buildControlButton(
                      label: 'Start',
                      icon: Icons.play_arrow_rounded,
                      color: const Color(0xFF00E676),
                      textColor: Colors.black,
                      onPressed: () => setState(() => _stopwatch.start()),
                    ),
                  if (_stopwatch.isRunning)
                    _buildControlButton(
                      label: 'Pause',
                      icon: Icons.pause_rounded,
                      color: Colors.orangeAccent,
                      textColor: Colors.black,
                      onPressed: () => setState(() => _stopwatch.stop()),
                    ),
                  const SizedBox(width: 16),
                  _buildControlButton(
                    label: 'Restart',
                    icon: Icons.replay_rounded,
                    color: Colors.white24,
                    textColor: Colors.white,
                    onPressed: _resetMatch,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamColumn({required bool isHome}) {
    final score = isHome ? _homeScore : _awayScore;
    final name = isHome ? _homeName : _awayName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _editTeamName(isHome),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 14, color: Colors.white38),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold, height: 1),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 30),
              onPressed: () {
                if (isHome && _homeScore > 0) setState(() => _homeScore--);
                if (!isHome && _awayScore > 0) setState(() => _awayScore--);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF00E676), size: 40),
              onPressed: () {
                setState(() {
                  if (isHome) _homeScore++;
                  else _awayScore++;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
