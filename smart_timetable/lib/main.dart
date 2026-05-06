import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_timetable/services/firestore_service.dart';
import 'services/genetic_algorithm.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GA Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
  final ga = GeneticAlgorithm(
    courses: [
      {'id': '1', 'name': 'Computer Networks'},
    ],
    lecturers: [
      {'id': '1', 'name': 'Dr. John Smith'},
    ],
    rooms: [
      {'id': '1', 'name': 'Room A1'},
    ],
    classes: [
      {'id': '1', 'name': 'Level 300'},
    ],
    timeslots: [
      {'day': 'Monday', 'startTime': '08:00', 'endTime': '10:00'},
      {'day': 'Tuesday', 'startTime': '08:00', 'endTime': '10:00'},
      {'day': 'Wednesday', 'startTime': '08:00', 'endTime': '10:00'},
    ],
  );

  // Run the GA
  final best = await ga.run(populationSize: 50, maxGenerations: 200);

  // Save to Firestore
  final firestoreService = FirestoreService();
  await firestoreService.saveTimetable(best);

  print('Done! Check Firestore console to verify.');
},            child: const Text('Run GA Test'),
          ),
        ),
      ),
    );
  }
}