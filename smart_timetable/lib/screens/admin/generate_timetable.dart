import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/genetic_algorithm.dart';
import '../../services/firestore_service.dart';

class GenerateTimetable extends StatefulWidget {
  const GenerateTimetable({super.key});

  @override
  State<GenerateTimetable> createState() => _GenerateTimetableState();
}

class _GenerateTimetableState extends State<GenerateTimetable> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isGenerating = false;
  String? _statusMessage;
  String? _errorMessage;
  int _bestScore = -1;
  int _generationsRun = 0;

  Future<void> _generateTimetable() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Fetching data from Firestore...';
      _errorMessage = null;
      _bestScore = -1;
      _generationsRun = 0;
    });

    try {
      final coursesSnap = await _db.collection('courses').get();
      final lecturersSnap = await _db.collection('lecturers').get();
      final roomsSnap = await _db.collection('rooms').get();
      final classesSnap = await _db.collection('classes').get();
      final timeslotsSnap = await _db.collection('timeslots').get();

      if (coursesSnap.docs.isEmpty) {
        setState(
          () => _errorMessage = 'No courses found. Please add courses first.',
        );
        return;
      }
      if (lecturersSnap.docs.isEmpty) {
        setState(
          () =>
              _errorMessage = 'No lecturers found. Please add lecturers first.',
        );
        return;
      }
      if (roomsSnap.docs.isEmpty) {
        setState(
          () => _errorMessage = 'No rooms found. Please add rooms first.',
        );
        return;
      }
      if (classesSnap.docs.isEmpty) {
        setState(
          () => _errorMessage = 'No classes found. Please add classes first.',
        );
        return;
      }
      if (timeslotsSnap.docs.isEmpty) {
        setState(
          () => _errorMessage =
              'No timeslots found. Please configure settings first.',
        );
        return;
      }

      setState(() => _statusMessage = 'Running Genetic Algorithm...');

      final courses = coursesSnap.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': data['name']};
      }).toList();

      final lecturers = lecturersSnap.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': data['name']};
      }).toList();

      final rooms = roomsSnap.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': data['name']};
      }).toList();

      final classes = classesSnap.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': data['name']};
      }).toList();

      final timeslots = timeslotsSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'day': data['day'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
        };
      }).toList();

      final ga = GeneticAlgorithm(
        courses: courses,
        lecturers: lecturers,
        rooms: rooms,
        classes: classes,
        timeslots: timeslots,
      );

      final result = await ga.run(populationSize: 100, maxGenerations: 500);

      if (result == null) {
        setState(
          () => _errorMessage = 'GA failed to generate a timetable. Try again.',
        );
        return;
      }

      setState(() {
        _statusMessage = 'Saving timetable to Firestore...';
        _bestScore = result.timetable.fitnessScore;
        _generationsRun = result.generations;
      });

      await _firestoreService.saveTimetable(result.timetable);

      setState(() {
        _statusMessage = result.timetable.fitnessScore == 0
            ? '✅ Perfect timetable generated with zero conflicts!'
            : '⚠️ Timetable generated with ${result.timetable.fitnessScore} conflict(s). Consider regenerating.';
      });
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 48,
                color: Color(0xFF1F5C8B),
              ),
              const SizedBox(height: 16),
              const Text(
                'Generate Timetable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F5C8B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The Genetic Algorithm will automatically generate a conflict-free timetable based on your courses, lecturers, rooms and timeslots.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('courses').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _statusRow(
                    Icons.book_outlined,
                    'Courses',
                    '$count found',
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('lecturers').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _statusRow(
                    Icons.people_outlined,
                    'Lecturers',
                    '$count found',
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('rooms').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _statusRow(
                    Icons.meeting_room_outlined,
                    'Rooms',
                    '$count found',
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('timeslots').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _statusRow(
                    Icons.access_time,
                    'Timeslots',
                    '$count found',
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F1FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1F5C8B),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEAF0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_bestScore >= 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bestScore == 0
                        ? const Color(0xFFE1F5EE)
                        : const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Final score: $_bestScore conflict(s)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _bestScore == 0
                              ? const Color(0xFF0D6B4A)
                              : const Color(0xFF633806),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed in $_generationsRun generation(s)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _bestScore == 0
                              ? const Color(0xFF0D6B4A)
                              : const Color(0xFF633806),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateTimetable,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Timetable',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5C8B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1F5C8B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
