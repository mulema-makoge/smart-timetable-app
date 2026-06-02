import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:smart_timetable/services/genetic_algorithm.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GeneticAlgorithm ga;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    ga = GeneticAlgorithm(
      courses: [
        {'id': '1', 'name': 'Computer Networks'},
        {'id': '2', 'name': 'Data Structures'},
      ],
      lecturers: [
        {'id': '1', 'name': 'Dr. John Smith'},
        {'id': '2', 'name': 'Dr. Jane Doe'},
      ],
      rooms: [
        {'id': '1', 'name': 'Room A1'},
        {'id': '2', 'name': 'Room B2'},
      ],
      classes: [
        {'id': '1', 'name': 'Level 300'},
        {'id': '2', 'name': 'Level 400'},
      ],
      timeslots: [
        {'day': 'Monday', 'startTime': '08:00', 'endTime': '10:00'},
        {'day': 'Monday', 'startTime': '10:00', 'endTime': '12:00'},
        {'day': 'Tuesday', 'startTime': '08:00', 'endTime': '10:00'},
        {'day': 'Tuesday', 'startTime': '10:00', 'endTime': '12:00'},
      ],
    );
  });

  group('GA Integration Tests', () {
    test('GA runs and returns a valid timetable', () async {
      final result = await ga.run(populationSize: 20, maxGenerations: 100);

      expect(result, isNotNull);
      expect(result!.timetable.slots.length, 2);
      expect(result.timetable.fitnessScore, greaterThanOrEqualTo(0));
      expect(result.generations, greaterThan(0));
    });

    test('GA result has zero or minimal conflicts', () async {
      final result = await ga.run(populationSize: 50, maxGenerations: 200);

      expect(result, isNotNull);
      expect(result!.timetable.fitnessScore, 0);
    });

    test('GA saves timetable to Firestore correctly', () async {
      final result = await ga.run(populationSize: 20, maxGenerations: 100);

      expect(result, isNotNull);

      // Save to fake Firestore
      for (var slot in result!.timetable.slots) {
        await fakeFirestore.collection('timetables').add(slot.toMap());
      }

      // Verify saved correctly
      final snapshot = await fakeFirestore.collection('timetables').get();
      expect(snapshot.docs.length, result.timetable.slots.length);
    });

    test('GA timetable slots have all required fields', () async {
      final result = await ga.run(populationSize: 20, maxGenerations: 100);

      expect(result, isNotNull);
      for (var slot in result!.timetable.slots) {
        expect(slot.courseId, isNotEmpty);
        expect(slot.courseName, isNotEmpty);
        expect(slot.lecturerId, isNotEmpty);
        expect(slot.lecturerName, isNotEmpty);
        expect(slot.roomId, isNotEmpty);
        expect(slot.roomName, isNotEmpty);
        expect(slot.classId, isNotEmpty);
        expect(slot.className, isNotEmpty);
        expect(slot.day, isNotEmpty);
        expect(slot.startTime, isNotEmpty);
        expect(slot.endTime, isNotEmpty);
      }
    });

    test('Regenerating timetable clears old one in Firestore', () async {
      // Save first timetable
      final result1 = await ga.run(populationSize: 20, maxGenerations: 100);
      for (var slot in result1!.timetable.slots) {
        await fakeFirestore.collection('timetables').add(slot.toMap());
      }

      // Clear and save second timetable
      final existing = await fakeFirestore.collection('timetables').get();
      for (var doc in existing.docs) {
        await doc.reference.delete();
      }

      final result2 = await ga.run(populationSize: 20, maxGenerations: 100);
      for (var slot in result2!.timetable.slots) {
        await fakeFirestore.collection('timetables').add(slot.toMap());
      }

      // Verify only latest timetable exists
      final snapshot = await fakeFirestore.collection('timetables').get();
      expect(snapshot.docs.length, result2.timetable.slots.length);
    });
  });
}
