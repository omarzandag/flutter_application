import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_notification.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  late final FirebaseService _service;
  final _formKey = GlobalKey<FormState>();
  String _selectedTrainingType = 'Match';
  final List<String> _trainingTypes = ['Match', 'Physical', 'Tactical', 'Technical'];
  final _teamACtrl = TextEditingController();
  final _teamBCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _stadiumCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
  }

  @override
  void dispose() {
    _teamACtrl.dispose();
    _teamBCtrl.dispose();
    _durationCtrl.dispose();
    _stadiumCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeCtrl.text = picked.format(context);
      });
    }
  }

  Future<void> _saveSession() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        CustomNotification.show(context, title: 'Validation', message: 'Please select date and time', isSuccess: false);
        return;
      }
      try {
        final session = Session(
          title: _selectedTrainingType,
          teamA: _teamACtrl.text,
          teamB: _teamBCtrl.text,
          date: _dateCtrl.text,
          timeStart: _timeCtrl.text,
          duration: _durationCtrl.text.isEmpty ? '90 min' : _durationCtrl.text,
          stadium: _stadiumCtrl.text.isEmpty ? 'Main Field' : _stadiumCtrl.text,
        );
        await _service.addSession(session);
        if (mounted) {
          CustomNotification.show(context, title: 'Success', message: 'Session saved successfully!');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          CustomNotification.show(context, title: 'Error', message: 'Failed: $e', isSuccess: false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Session')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDropdown(),
            _buildTextField(_teamACtrl, 'Team A', Icons.groups),
            _buildTextField(_teamBCtrl, 'Team B', Icons.groups),
            const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 12),
            _buildTimePicker(),
            const SizedBox(height: 12),
            _buildTextField(_durationCtrl, 'Duration (e.g., 90 min)', Icons.timer),
            _buildTextField(_stadiumCtrl, 'Stadium', Icons.location_on),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saveSession, child: const Text('Save Session')),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _dateCtrl,
      decoration: InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      readOnly: true,
      onTap: _selectDate,
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildTimePicker() {
    return TextFormField(
      controller: _timeCtrl,
      decoration: InputDecoration(labelText: 'Time Start', prefixIcon: Icon(Icons.access_time), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      readOnly: true,
      onTap: _selectTime,
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedTrainingType,
        decoration: InputDecoration(labelText: 'Training Type', prefixIcon: const Icon(Icons.category), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        items: _trainingTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedTrainingType = val);
          }
        },
      ),
    );
  }
}