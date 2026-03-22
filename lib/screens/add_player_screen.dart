import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_notification.dart';

class AddPlayerScreen extends StatefulWidget {
  final Player? player;
  const AddPlayerScreen({super.key, this.player});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  late final FirebaseService _service;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _shirtCtrl;
  late TextEditingController _posCtrl;
  late TextEditingController _teamCtrl;
  late TextEditingController _goalsCtrl;
  late TextEditingController _assistsCtrl;
  late TextEditingController _yellowCtrl;
  late TextEditingController _redCtrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _isEditing = widget.player != null;
    _nameCtrl = TextEditingController(text: widget.player?.fullName ?? '');
    _ageCtrl = TextEditingController(text: widget.player?.age.toString() ?? '');
    _shirtCtrl = TextEditingController(text: widget.player?.shirtNumber.toString() ?? '');
    _posCtrl = TextEditingController(text: widget.player?.position ?? '');
    _teamCtrl = TextEditingController(text: widget.player?.team ?? '');
    _goalsCtrl = TextEditingController(text: widget.player?.goals.toString() ?? '0');
    _assistsCtrl = TextEditingController(text: widget.player?.assists.toString() ?? '0');
    _yellowCtrl = TextEditingController(text: widget.player?.yellowCards.toString() ?? '0');
    _redCtrl = TextEditingController(text: widget.player?.redCards.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _shirtCtrl.dispose();
    _posCtrl.dispose();
    _teamCtrl.dispose();
    _goalsCtrl.dispose();
    _assistsCtrl.dispose();
    _yellowCtrl.dispose();
    _redCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePlayer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final player = Player(
          id: widget.player?.id,
          fullName: _nameCtrl.text,
          age: int.parse(_ageCtrl.text),
          shirtNumber: int.parse(_shirtCtrl.text),
          position: _posCtrl.text,
          team: _teamCtrl.text,
          status: widget.player?.status ?? 'Available',
          goals: int.parse(_goalsCtrl.text),
          assists: int.parse(_assistsCtrl.text),
          yellowCards: int.parse(_yellowCtrl.text),
          redCards: int.parse(_redCtrl.text),
        );

        if (_isEditing) {
          await _service.updatePlayer(player);
        } else {
          await _service.addPlayer(player);
        }

        if (mounted) {
          CustomNotification.show(
            context,
            title: 'Success',
            message: _isEditing ? 'Player updated successfully!' : 'Player added successfully!',
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          CustomNotification.show(
            context,
            title: 'Error',
            message: 'Failed to save player: $e',
            isSuccess: false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Player' : 'Add Player')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_nameCtrl, 'Full Name', Icons.person),
            _buildTextField(_ageCtrl, 'Age', Icons.cake, isNumber: true),
            _buildTextField(_shirtCtrl, 'Shirt Number', Icons.sports_soccer, isNumber: true),
            _buildTextField(_posCtrl, 'Position', Icons.sports),
            _buildTextField(_teamCtrl, 'Team', Icons.groups),
            const SizedBox(height: 20),
            const Text('Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 12),
            _buildTextField(_goalsCtrl, 'Goals', Icons.sports_soccer, isNumber: true),
            _buildTextField(_assistsCtrl, 'Assists', Icons.near_me, isNumber: true),
            _buildTextField(_yellowCtrl, 'Yellow Cards', Icons.warning_amber, isNumber: true),
            _buildTextField(_redCtrl, 'Red Cards', Icons.cancel, isNumber: true),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _savePlayer, child: Text(_isEditing ? 'Update Player' : 'Add Player')),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }
}