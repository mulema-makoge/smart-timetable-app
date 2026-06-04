import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _slotDurationController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;

  final List<String> _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday', 'Sunday'
  ];
  List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _slotDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc =
          await _db.collection('settings').doc('schedule').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _startTimeController.text = data['startTime'] ?? '08:00';
          _endTimeController.text = data['endTime'] ?? '18:00';
          _slotDurationController.text =
              data['slotDuration']?.toString() ?? '60';
          _selectedDays =
              List<String>.from(data['schoolDays'] ?? []);
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load settings.');
    }
  }

  bool _validate() {
    if (_startTimeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Start time cannot be empty.');
      return false;
    }
    if (_endTimeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'End time cannot be empty.');
      return false;
    }
    if (_slotDurationController.text.trim().isEmpty) {
      setState(
          () => _errorMessage = 'Slot duration cannot be empty.');
      return false;
    }
    if (int.tryParse(_slotDurationController.text.trim()) == null) {
      setState(
          () => _errorMessage = 'Slot duration must be a number.');
      return false;
    }
    if (_selectedDays.isEmpty) {
      setState(() => _errorMessage =
          'Please select at least one school day.');
      return false;
    }
    return true;
  }

  Future<void> _saveSettings() async {
    if (!_validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _db.collection('settings').doc('schedule').set({
        'startTime': _startTimeController.text.trim(),
        'endTime': _endTimeController.text.trim(),
        'slotDuration':
            int.parse(_slotDurationController.text.trim()),
        'schoolDays': _selectedDays,
      });

      await _generateTimeslots();
      setState(
          () => _successMessage = 'Settings saved successfully!');
    } catch (e) {
      setState(() =>
          _errorMessage = 'Failed to save settings. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateTimeslots() async {
    final start = _startTimeController.text.trim();
    final end = _endTimeController.text.trim();
    final duration =
        int.parse(_slotDurationController.text.trim());

    final startParts = start.split(':');
    final endParts = end.split(':');
    int startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes =
        int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final existing = await _db.collection('timeslots').get();
    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    for (var day in _selectedDays) {
      int current = startMinutes;
      while (current + duration <= endMinutes) {
        final slotStart =
            '${(current ~/ 60).toString().padLeft(2, '0')}:${(current % 60).toString().padLeft(2, '0')}';
        final slotEnd =
            '${((current + duration) ~/ 60).toString().padLeft(2, '0')}:${((current + duration) % 60).toString().padLeft(2, '0')}';

        await _db.collection('timeslots').add({
          'day': day,
          'startTime': slotStart,
          'endTime': slotEnd,
        });

        current += duration;
      }
    }
  }

  Widget _buildSettingsForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Schedule Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F5C8B),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _startTimeController,
            decoration: InputDecoration(
              labelText: 'School Start Time',
              hintText: 'e.g. 08:00',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _endTimeController,
            decoration: InputDecoration(
              labelText: 'School End Time',
              hintText: 'e.g. 18:00',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _slotDurationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Slot Duration (minutes)',
              hintText: 'e.g. 60',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'School Days',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F5C8B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allDays.map((day) {
              final isSelected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
                selectedColor: const Color(0xFFD6E4F0),
                checkmarkColor: const Color(0xFF1F5C8B),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1F5C8B)
                      : Colors.grey,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!,
                style: const TextStyle(
                    color: Colors.red, fontSize: 13)),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 12),
            Text(_successMessage!,
                style: const TextStyle(
                    color: Colors.green, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F5C8B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white)
                : const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeslotsList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Generated Timeslots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F5C8B),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('timeslots')
                .orderBy('day')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No timeslots yet.\nSave settings to generate.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data =
                      docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.access_time,
                        color: Color(0xFF1F5C8B), size: 18),
                    title: Text(
                      '${data['day']}  •  ${data['startTime']} - ${data['endTime']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return isMobile
        ? SingleChildScrollView(
            child: Column(
              children: [
                _buildSettingsForm(),
                const SizedBox(height: 24),
                _buildTimeslotsList(),
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 400, child: _buildSettingsForm()),
              const SizedBox(width: 24),
              Expanded(
                child: SingleChildScrollView(
                    child: _buildTimeslotsList()),
              ),
            ],
          );
  }
}