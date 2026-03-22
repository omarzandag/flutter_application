import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/player.dart';
import '../services/firebase_service.dart';
import '../widgets/stadium_painter.dart';

// Drawing Model
class DrawingLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  DrawingLine({required this.points, this.color = Colors.white, this.strokeWidth = 3.0});
}

// Position label per slot index for each formation
const Map<String, List<String>> _positionLabels = {
  '4-3-3':     ['GK','LB','CB','CB','RB','CM','CDM','CM','LW','ST','RW'],
  '4-4-2':     ['GK','LB','CB','CB','RB','LM','CM','CM','RM','ST','ST'],
  '3-5-2':     ['GK','CB','CB','CB','LWB','CM','CDM','CM','RWB','ST','ST'],
  '4-2-3-1':   ['GK','LB','CB','CB','RB','CDM','CDM','LAM','CAM','RAM','ST'],
  '4-1-4-1':   ['GK','LB','CB','CB','RB','CDM','LM','CM','CM','RM','ST'],
  '5-3-2':     ['GK','LB','CB','CB','CB','RB','CM','CM','CM','ST','ST'],
  '4-3-2-1':   ['GK','LB','CB','CB','RB','CM','CM','CM','SS','SS','ST'],
  '3-4-3':     ['GK','CB','CB','CB','LM','CM','CM','RM','LW','ST','RW'],
};

const List<String> _formations = ['4-3-3', '4-4-2', '3-5-2', '4-2-3-1', '4-1-4-1', '5-3-2', '4-3-2-1', '3-4-3'];

const Map<String, List<Offset>> _formationLayouts = {
  '4-3-3': [
    Offset(0.5, 0.9),
    Offset(0.15, 0.7), Offset(0.38, 0.75), Offset(0.62, 0.75), Offset(0.85, 0.7),
    Offset(0.3, 0.5), Offset(0.5, 0.55), Offset(0.7, 0.5),
    Offset(0.15, 0.25), Offset(0.5, 0.2), Offset(0.85, 0.25),
  ],
  '4-4-2': [
    Offset(0.5, 0.9),
    Offset(0.15, 0.7), Offset(0.38, 0.75), Offset(0.62, 0.75), Offset(0.85, 0.7),
    Offset(0.15, 0.45), Offset(0.38, 0.5), Offset(0.62, 0.5), Offset(0.85, 0.45),
    Offset(0.35, 0.2), Offset(0.65, 0.2),
  ],
  '3-5-2': [
    Offset(0.5, 0.9),
    Offset(0.25, 0.75), Offset(0.5, 0.8), Offset(0.75, 0.75),
    Offset(0.1, 0.5), Offset(0.3, 0.55), Offset(0.5, 0.6), Offset(0.7, 0.55), Offset(0.9, 0.5),
    Offset(0.35, 0.2), Offset(0.65, 0.2),
  ],
  '4-2-3-1': [
    Offset(0.5, 0.9),
    Offset(0.15, 0.7), Offset(0.38, 0.75), Offset(0.62, 0.75), Offset(0.85, 0.7),
    Offset(0.35, 0.6), Offset(0.65, 0.6),
    Offset(0.2, 0.35), Offset(0.5, 0.35), Offset(0.8, 0.35),
    Offset(0.5, 0.15),
  ],
  '4-1-4-1': [
    Offset(0.5, 0.9),
    Offset(0.15, 0.7), Offset(0.38, 0.75), Offset(0.62, 0.75), Offset(0.85, 0.7),
    Offset(0.5, 0.6),
    Offset(0.15, 0.45), Offset(0.38, 0.45), Offset(0.62, 0.45), Offset(0.85, 0.45),
    Offset(0.5, 0.2),
  ],
  '5-3-2': [
    Offset(0.5, 0.9),
    Offset(0.1, 0.7), Offset(0.3, 0.75), Offset(0.5, 0.8), Offset(0.7, 0.75), Offset(0.9, 0.7),
    Offset(0.25, 0.5), Offset(0.5, 0.55), Offset(0.75, 0.5),
    Offset(0.35, 0.2), Offset(0.65, 0.2),
  ],
  '4-3-2-1': [
    Offset(0.5, 0.9),
    Offset(0.15, 0.7), Offset(0.38, 0.75), Offset(0.62, 0.75), Offset(0.85, 0.7),
    Offset(0.25, 0.5), Offset(0.5, 0.55), Offset(0.75, 0.5),
    Offset(0.35, 0.35), Offset(0.65, 0.35),
    Offset(0.5, 0.15),
  ],
  '3-4-3': [
    Offset(0.5, 0.9),
    Offset(0.25, 0.75), Offset(0.5, 0.8), Offset(0.75, 0.75),
    Offset(0.1, 0.5), Offset(0.38, 0.55), Offset(0.62, 0.55), Offset(0.9, 0.5),
    Offset(0.2, 0.25), Offset(0.5, 0.2), Offset(0.8, 0.25),
  ],
};

const Map<String, List<Offset>> _simulationTemplates = {
  'Corner': [
    Offset(0.5, 0.95), // GK stays deep
    Offset(0.1, 0.1),  // Kicker
    Offset(0.45, 0.15), Offset(0.55, 0.2), Offset(0.5, 0.1), // Attackers in box
    Offset(0.4, 0.25), Offset(0.6, 0.25), Offset(0.5, 0.3),  // Edge of box
    Offset(0.2, 0.6), Offset(0.8, 0.6), Offset(0.5, 0.6),    // Rest stay back
  ],
    'Foul': [
      Offset(0.5, 0.95), // GK
      Offset(0.5, 0.35), Offset(0.44, 0.35), Offset(0.56, 0.35), Offset(0.38, 0.35), // 4-man Wall
      Offset(0.2, 0.4), Offset(0.8, 0.4), // Wide markers
      Offset(0.4, 0.2), Offset(0.6, 0.2), // Central markers
      Offset(0.5, 0.5), Offset(0.5, 0.05), // Deep cover & High press
    ],
  'Defense': [
    Offset(0.5, 0.95), // GK
    Offset(0.2, 0.85), Offset(0.4, 0.85), Offset(0.6, 0.85), Offset(0.8, 0.85), // Back 4
    Offset(0.3, 0.75), Offset(0.5, 0.75), Offset(0.7, 0.75), // Mid 3
    Offset(0.4, 0.65), Offset(0.6, 0.65), // Forwards back
    Offset(0.5, 0.55),
  ],
  'Attack': [
    Offset(0.5, 0.8),  // GK pushed up
    Offset(0.1, 0.4), Offset(0.4, 0.35), Offset(0.6, 0.35), Offset(0.9, 0.4), // High line
    Offset(0.3, 0.2), Offset(0.5, 0.25), Offset(0.7, 0.2), // Overloading
    Offset(0.2, 0.1), Offset(0.5, 0.05), Offset(0.8, 0.1), // Final third
  ],
};

class FormationScreen extends StatefulWidget {
  const FormationScreen({super.key});

  @override
  State<FormationScreen> createState() => _FormationScreenState();
}

class _FormationScreenState extends State<FormationScreen> {
  late final FirebaseService _service;
  Map<int, Player> _fieldPlayers = {};
  List<Player> _benchPlayers = [];
  Map<int, Offset> _manualOffsets = {};
  bool _isLoading = false;
  String _currentFormation = '4-3-3';
  int? _draggingSlot;
  final GlobalKey _stadiumKey = GlobalKey();

  // Drawing state
  bool _isDrawingMode = false;
  List<DrawingLine> _lines = [];
  DrawingLine? _currentLine;
  Color _drawingColor = Colors.yellowAccent;

  // Simulation state
  bool _isInstructionMode = false;
  bool _isRunningSimulation = false;
  bool _showSimControls = false;
  int _activeSimIndex = -1; // For sequential movement
  Map<int, Offset> _instructionOffsets = {};

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final allPlayers = await _service.getPlayers();
      final eligiblePlayers = allPlayers.where((p) =>
        p.status == 'Available' || p.status == 'Injured'
      ).toList();

      final formationData = await _service.getFormation();

      if (mounted) {
        setState(() {
          if (formationData != null && formationData['field'] != null) {
            _currentFormation = formationData['formation']?.toString() ?? '4-3-3';
            
            final fieldList = (formationData['field'] as List?) ?? [];
            final benchList = (formationData['bench'] as List?) ?? [];

            Player mapToPlayer(Map p) {
              final id = p['id']?.toString() ?? '';
              return Player.fromMap(id, Map<String, dynamic>.from(p));
            }

            _fieldPlayers.clear();
            _manualOffsets.clear();
            for (int i = 0; i < fieldList.length; i++) {
              if (i >= 11) break;
              final pMap = fieldList[i] as Map;
              final id = pMap['id']?.toString() ?? '';
              
              try {
                final latestPlayer = eligiblePlayers.firstWhere((p) => p.id == id);
                int slotIndex = pMap['slotIndex'] ?? i;
                _fieldPlayers[slotIndex] = latestPlayer;
                if (pMap.containsKey('manualX') && pMap.containsKey('manualY')) {
                  _manualOffsets[slotIndex] = Offset(
                    (pMap['manualX'] as num).toDouble(), 
                    (pMap['manualY'] as num).toDouble()
                  );
                }
              } catch (e) {
                // Player no longer exists or is not eligible
              }
            }

            final fieldPlayerIds = _fieldPlayers.values.map((p) => p.id).toSet();
            _benchPlayers = eligiblePlayers.where((p) => !fieldPlayerIds.contains(p.id)).toList();
          } else {
            _fieldPlayers.clear();
            _benchPlayers = List.from(eligiblePlayers);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading formation: $e')));
      }
    }
  }

  Future<void> _saveFormation() async {
    final fieldMaps = _fieldPlayers.entries.map((e) {
      var map = e.value.toMap();
      map['slotIndex'] = e.key;
      if (_manualOffsets.containsKey(e.key)) {
        map['manualX'] = _manualOffsets[e.key]!.dx;
        map['manualY'] = _manualOffsets[e.key]!.dy;
      }
      return map;
    }).toList();
    
    final benchMaps = _benchPlayers.map((p) => p.toMap()).toList();

    await _service.saveFormation({
      'formation': _currentFormation,
      'field': fieldMaps,
      'bench': benchMaps,
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Formation Saved!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _shareTactics() async {
    try {
      RenderRepaintBoundary boundary = _stadiumKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/tactics_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);
      
      await Share.shareXFiles([XFile(imagePath)], text: 'Check out my new football tactics!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  void _showPlayerSelectionSheet(int slotIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              width: 40, height: 5,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(5)),
            ),
            Text(
              'Select Player — Slot: ${_positionLabels[_currentFormation]?[slotIndex] ?? '#$slotIndex'}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _benchPlayers.isEmpty 
              ? Center(child: Text('No available players on bench', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)))
              : ListView.builder(
                itemCount: _benchPlayers.length,
                itemBuilder: (context, i) {
                  final player = _benchPlayers[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: player.status == 'Injured' ? Colors.orange : const Color(0xFF004D40),
                      child: Text(player.shirtNumber.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(player.fullName, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                    subtitle: Text(player.position, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                    trailing: Icon(Icons.add_circle, color: isDark ? const Color(0xFF00E676) : Colors.green),
                    onTap: () {
                      _assignPlayerToSlot(player, slotIndex);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            if (_fieldPlayers.containsKey(slotIndex))
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _removePlayerFromSlot(slotIndex);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.remove_circle),
                  label: const Text('Remove from field'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              )
          ],
        ),
      ),
    );
  }

  void _assignPlayerToSlot(Player player, int slotIndex) {
    setState(() {
      _benchPlayers.removeWhere((p) => p.id == player.id);
      if (_fieldPlayers.containsKey(slotIndex)) {
        _benchPlayers.add(_fieldPlayers[slotIndex]!);
      }
      _fieldPlayers[slotIndex] = player;
    });
  }

  void _removePlayerFromSlot(int slotIndex) {
    setState(() {
      if (_fieldPlayers.containsKey(slotIndex)) {
        _benchPlayers.add(_fieldPlayers[slotIndex]!);
        _fieldPlayers.remove(slotIndex);
        _instructionOffsets.remove(slotIndex);
      }
    });
  }

  void _applyTemplate(String type) {
    setState(() {
      _isInstructionMode = true;
      final template = _simulationTemplates[type]!;
      for (int i = 0; i < 11; i++) {
        _instructionOffsets[i] = template[i];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied $type Template'), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _runSimulation() async {
    if (_instructionOffsets.isEmpty || _isRunningSimulation) {
      if (_instructionOffsets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set instructions first!')),
        );
      }
      return;
    }
    
    setState(() {
      _isRunningSimulation = true;
      _isInstructionMode = false; // Snap back to formation first
      _activeSimIndex = -1;
    });

    // Wait for the snap-back (2.0s animation)
    await Future.delayed(const Duration(milliseconds: 2000));

    // Move players one by one from 0 to 10
    for (int i = 0; i < 11; i++) {
      if (!_isRunningSimulation) break; // Guard against reset
      if (_fieldPlayers.containsKey(i)) {
        setState(() => _activeSimIndex = i);
        // Wait for player to arrive (2.0s animation + 0.2s pause)
        await Future.delayed(const Duration(milliseconds: 2200)); 
      }
    }
  }

  void _resetSimulation() {
    setState(() {
      _isRunningSimulation = false;
      _isInstructionMode = false;
      _activeSimIndex = -1;
      _instructionOffsets.clear();
    });
  }

  void _toggleInstructionMode() {
    setState(() {
      _isInstructionMode = !_isInstructionMode;
      // Toggling instruction mode stops any active simulation to avoid conflicts
      _isRunningSimulation = false;
      _activeSimIndex = -1;
    });
  }

  Widget _simButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tactics Board'),
        elevation: 0,
        actions: [
          // Drawing color picker (only in draw mode)
          if (_isDrawingMode)
            Row(
              children: [
                for (final c in [Colors.yellowAccent, Colors.redAccent, Colors.white, Colors.cyanAccent])
                  GestureDetector(
                    onTap: () => setState(() => _drawingColor = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _drawingColor == c ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
              ],
            ),
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.draw : Icons.draw_outlined),
            onPressed: () => setState(() => _isDrawingMode = !_isDrawingMode),
            tooltip: 'Draw Mode',
          ),
          if (_isDrawingMode)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _lines.clear()), tooltip: 'Clear'),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareTactics, tooltip: 'Share'),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveFormation, tooltip: 'Save'),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // ── Formation Selector ──
              Container(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Formation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentFormation,
                          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF004D40),
                            fontSize: 15,
                          ),
                          items: _formations.map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF004D40))),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null && val != _currentFormation) {
                              setState(() {
                                _currentFormation = val;
                                _manualOffsets.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    // Squad count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_fieldPlayers.length}/11',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Simulation Controls ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _simButton(
                  label: _showSimControls ? 'Hide Simulation' : 'Tactics Simulation 🎮',
                  icon: _showSimControls ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF004D40),
                  onPressed: () => setState(() => _showSimControls = !_showSimControls),
                ),
              ),

              if (_showSimControls)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _simButton(
                          label: _isInstructionMode ? 'Instructions ON' : 'Set Instructions',
                          icon: Icons.edit_location_alt,
                          color: _isInstructionMode ? Colors.orange : const Color(0xFF004D40),
                          onPressed: _toggleInstructionMode,
                        ),
                        const SizedBox(width: 8),
                        _simButton(
                          label: 'Run',
                          icon: Icons.play_arrow,
                          color: Colors.green,
                          onPressed: _runSimulation,
                        ),
                        const SizedBox(width: 8),
                        _simButton(
                          label: 'Reset',
                          icon: Icons.refresh,
                          color: Colors.redAccent,
                          onPressed: _resetSimulation,
                        ),
                        const VerticalDivider(width: 20, thickness: 1, indent: 5, endIndent: 5),
                        // Templates
                        for (final type in ['Corner', 'Foul', 'Defense', 'Attack'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _applyTemplate(type),
                              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.blueGrey.shade50,
                              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.blueGrey.shade700),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // ── Football Field ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final layout = _formationLayouts[_currentFormation]!;
                    final labels = _positionLabels[_currentFormation]!;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: RepaintBoundary(
                          key: _stadiumKey,
                          child: Stack(
                            children: [
                              // Ground (cached to prevent re-drawing every drag frame)
                              Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: StadiumPainter()))),
                              // Drawings
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: DrawingLinesPainter(lines: [..._lines, if (_currentLine != null) _currentLine!]),
                                ),
                              ),
                              // Instruction Path Lines
                              if (_isInstructionMode || (_isRunningSimulation && _activeSimIndex != -1))
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: InstructionPathsPainter(
                                      fieldPlayers: _fieldPlayers,
                                      manualOffsets: _manualOffsets,
                                      instructionOffsets: _instructionOffsets,
                                      currentLayout: layout,
                                    ),
                                  ),
                                ),
                              // Draw gesture
                              if (_isDrawingMode)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (d) => setState(() => _currentLine = DrawingLine(points: [d.localPosition], color: _drawingColor)),
                                    onPanUpdate: (d) => setState(() {
                                      final pts = List<Offset>.from(_currentLine!.points)..add(d.localPosition);
                                      _currentLine = DrawingLine(points: pts, color: _drawingColor);
                                    }),
                                    onPanEnd: (_) => setState(() {
                                      if (_currentLine != null) { _lines.add(_currentLine!); _currentLine = null; }
                                    }),
                                  ),
                                ),
                              // Player slots
                              for (int i = 0; i < 11; i++)
                                AnimatedPositioned(
                                  duration: _draggingSlot == i ? Duration.zero : const Duration(milliseconds: 2000), // Smoother, slower
                                  curve: Curves.easeInOut,
                                  left: (((_isRunningSimulation && i <= _activeSimIndex ? (_instructionOffsets[i] ?? _manualOffsets[i] ?? layout[i]) : (_isInstructionMode ? (_instructionOffsets[i] ?? _manualOffsets[i] ?? layout[i]) : (_manualOffsets[i] ?? layout[i]))).dx * constraints.maxWidth)) - 28,
                                  top: (((_isRunningSimulation && i <= _activeSimIndex ? (_instructionOffsets[i] ?? _manualOffsets[i] ?? layout[i]) : (_isInstructionMode ? (_instructionOffsets[i] ?? _manualOffsets[i] ?? layout[i]) : (_manualOffsets[i] ?? layout[i]))).dy * constraints.maxHeight)) - 36,
                                  child: IgnorePointer(
                                    ignoring: _isDrawingMode,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onPanStart: (_) { if (!_isDrawingMode) setState(() => _draggingSlot = i); },
                                      onPanEnd: (_) { if (!_isDrawingMode) setState(() => _draggingSlot = null); },
                                      onPanUpdate: (d) {
                                        if (!_isDrawingMode && _draggingSlot == i) {
                                          setState(() {
                                            if (_isInstructionMode) {
                                              final cur = _instructionOffsets[i] ?? _manualOffsets[i] ?? layout[i];
                                              _instructionOffsets[i] = Offset(
                                                (cur.dx + d.delta.dx / constraints.maxWidth).clamp(0.0, 1.0),
                                                (cur.dy + d.delta.dy / constraints.maxHeight).clamp(0.0, 1.0),
                                              );
                                            } else {
                                              final cur = _manualOffsets[i] ?? layout[i];
                                              _manualOffsets[i] = Offset(
                                                (cur.dx + d.delta.dx / constraints.maxWidth).clamp(0.0, 1.0),
                                                (cur.dy + d.delta.dy / constraints.maxHeight).clamp(0.0, 1.0),
                                              );
                                            }
                                          });
                                        }
                                      },
                                      child: _buildSlotOrPlayer(i, labels[i]),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),

              // ── Bench Area ──
              Container(
                constraints: const BoxConstraints(minHeight: 110, maxHeight: 130),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.airline_seat_recline_normal, size: 16, color: isDark ? Colors.white54 : Colors.grey),
                          const SizedBox(width: 6),
                          Text('Bench (${_benchPlayers.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                          const SizedBox(width: 14),
                          _legendDot(Colors.green, 'Available', isDark),
                          const SizedBox(width: 10),
                          _legendDot(Colors.orange, 'Injured', isDark),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _benchPlayers.isEmpty
                          ? Center(child: Text('All players on field', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              itemCount: _benchPlayers.length,
                              itemBuilder: (ctx, index) {
                                final p = _benchPlayers[index];
                                final color = p.status == 'Injured' ? Colors.orange : Colors.green;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: color,
                                        child: Text(p.shirtNumber.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        p.fullName.split(' ').first,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _legendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[700])),
      ],
    );
  }

  Widget _buildSlotOrPlayer(int slotIndex, String positionLabel) {
    final player = _fieldPlayers[slotIndex];
    
    if (player == null) {
      return GestureDetector(
        onTap: () => _showPlayerSelectionSheet(slotIndex),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
              ),
              child: const Center(child: Icon(Icons.add, color: Colors.white70, size: 20)),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(positionLabel, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ],
        ),
      );
    } else {
      final isGK = positionLabel == 'GK';
      final isInjured = player.status == 'Injured';
      final ringColor = isGK ? const Color(0xFFFFD700) : (isInjured ? Colors.orange : Colors.white);
      final fillColor = isGK ? const Color(0xFF1A237E) : (isInjured ? Colors.deepOrange : const Color(0xFF004D40));

      return GestureDetector(
        onTap: () => _showPlayerSelectionSheet(slotIndex),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2.5),
                boxShadow: [
                  BoxShadow(color: fillColor.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3)),
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  '${player.shirtNumber}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.fullName.split(' ').last,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    positionLabel,
                    style: TextStyle(color: ringColor, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}

// Custom Painter for Drawing tactics lines
class DrawingLinesPainter extends CustomPainter {
  final List<DrawingLine> lines;
  DrawingLinesPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      if (line.points.isEmpty) continue;
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
        
      final path = Path()..moveTo(line.points.first.dx, line.points.first.dy);
      for (int i = 1; i < line.points.length; i++) {
        path.lineTo(line.points[i].dx, line.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingLinesPainter oldDelegate) => true;
}
class InstructionPathsPainter extends CustomPainter {
  final Map<int, Player> fieldPlayers;
  final Map<int, Offset> manualOffsets;
  final Map<int, Offset> instructionOffsets;
  final List<Offset> currentLayout;

  InstructionPathsPainter({
    required this.fieldPlayers,
    required this.manualOffsets,
    required this.instructionOffsets,
    required this.currentLayout,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 11; i++) {
      if (!fieldPlayers.containsKey(i)) continue;
      if (!instructionOffsets.containsKey(i)) continue;

      final start = manualOffsets[i] ?? currentLayout[i];
      final end = instructionOffsets[i]!;

      if (start == end) continue;

      final p1 = Offset(start.dx * size.width, start.dy * size.height);
      final p2 = Offset(end.dx * size.width, end.dy * size.height);

      // Draw path line
      canvas.drawLine(p1, p2, paint);

      // Draw arrowhead
      final angle = (p2 - p1).direction;
      const arrowSize = 8.0;
      final path = Path()
        ..moveTo(p2.dx, p2.dy)
        ..lineTo(p2.dx - arrowSize * math.cos(angle - 0.5), p2.dy - arrowSize * math.sin(angle - 0.5))
        ..lineTo(p2.dx - arrowSize * math.cos(angle + 0.5), p2.dy - arrowSize * math.sin(angle + 0.5))
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.5));
    }
  }

  @override
  bool shouldRepaint(covariant InstructionPathsPainter oldDelegate) => true;
}
