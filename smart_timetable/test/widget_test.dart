import 'package:flutter_test/flutter_test.dart';
import 'package:smart_timetable/models/timetable_model.dart';
import 'package:smart_timetable/services/genetic_algorithm.dart';

void main() {
  // Sample data for all tests
  final courses = [
    {'id': '1', 'name': 'Computer Networks'},
    {'id': '2', 'name': 'Data Structures'},
  ];
  final lecturers = [
    {'id': '1', 'name': 'Dr. John Smith'},
    {'id': '2', 'name': 'Dr. Jane Doe'},
  ];
  final rooms = [
    {'id': '1', 'name': 'Room A1'},
    {'id': '2', 'name': 'Room B2'},
  ];
  final classes = [
    {'id': '1', 'name': 'Level 300'},
    {'id': '2', 'name': 'Level 400'},
  ];
  final timeslots = [
    {'day': 'Monday', 'startTime': '08:00', 'endTime': '10:00'},
    {'day': 'Monday', 'startTime': '10:00', 'endTime': '12:00'},
    {'day': 'Tuesday', 'startTime': '08:00', 'endTime': '10:00'},
  ];

  late GeneticAlgorithm ga;

  setUp(() {
    ga = GeneticAlgorithm(
      courses: courses,
      lecturers: lecturers,
      rooms: rooms,
      classes: classes,
      timeslots: timeslots,
    );
  });

  group('Fitness Function Tests', () {
    test('Perfect timetable has zero conflicts', () {
      // Two courses at different times — no conflicts
      final timetable = Timetable(
        slots: [
          ScheduleSlot(
            courseId: '1',
            courseName: 'Computer Networks',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '1',
            roomName: 'Room A1',
            classId: '1',
            className: 'Level 300',
            day: 'Monday',
            startTime: '08:00',
            endTime: '10:00',
          ),
          ScheduleSlot(
            courseId: '2',
            courseName: 'Data Structures',
            lecturerId: '2',
            lecturerName: 'Dr. Jane Doe',
            roomId: '2',
            roomName: 'Room B2',
            classId: '2',
            className: 'Level 400',
            day: 'Monday',
            startTime: '10:00',
            endTime: '12:00',
          ),
        ],
      );

      expect(ga.calculateFitness(timetable), 0);
    });

    test('Lecturer clash is detected', () {
      // Same lecturer at same time — should be 1 conflict
      final timetable = Timetable(
        slots: [
          ScheduleSlot(
            courseId: '1',
            courseName: 'Computer Networks',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '1',
            roomName: 'Room A1',
            classId: '1',
            className: 'Level 300',
            day: 'Monday',
            startTime: '08:00',
            endTime: '10:00',
          ),
          ScheduleSlot(
            courseId: '2',
            courseName: 'Data Structures',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '2',
            roomName: 'Room B2',
            classId: '2',
            className: 'Level 400',
            day: 'Monday',
            startTime: '08:00',
            endTime: '10:00',
          ),
        ],
      );

      expect(ga.calculateFitness(timetable), greaterThan(0));
    });

    test('Room clash is detected', () {
      // Same room at same time — should be 1 conflict
      final timetable = Timetable(
        slots: [
          ScheduleSlot(
            courseId: '1',
            courseName: 'Computer Networks',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '1',
            roomName: 'Room A1',
            classId: '1',
            className: 'Level 300',
            day: 'Monday',
            startTime: '08:00',
            endTime: '10:00',
          ),
          ScheduleSlot(
            courseId: '2',
            courseName: 'Data Structures',
            lecturerId: '2',
            lecturerName: 'Dr. Jane Doe',
            roomId: '1',
            roomName: 'Room A1',
            classId: '2',
            className: 'Level 400',
            day: 'Monday',
            startTime: '08:00',
            endTime: '10:00',
          ),
        ],
      );

      expect(ga.calculateFitness(timetable), greaterThan(0));
    });

    test('Class clash is detected', () {
      // Same class at same time — should be 1 conflict
      final timetable = Timetable(
        slots: [
          ScheduleSlot(
            courseId: '1',
            courseName: 'Computer Networks',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '1',
            roomName: 'Room A1',
            classId: '1',
            className: 'Level 300',
            day: 'Monday',
            startTime: '08:00',
            endTime: '10:00',
          ),
          ScheduleSlot(
            courseId: '2',
            courseName: 'Data Structures',
            lecturerId: '2',
            lecturerName: 'Dr. Jane Doe',
            roomId: '2',
            roomName: 'Room B2',
            classId: '1',
            className: 'Level 300',
            day: 'Monday',
            startTime: '08:00',
            endTime: '10:00',
          ),
        ],
      );

      expect(ga.calculateFitness(timetable), greaterThan(0));
    });

    test('Different days never clash', () {
      // Same lecturer, room and class but different days — no conflict
      final timetable = Timetable(
        slots: [
          ScheduleSlot(
            courseId: '1',
            courseName: 'Computer Networks',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '1',
            roomName: 'Room A1',
            classId: '1',
            className: 'Level 300',
            day: 'Monday',
            startTime: '08:00',
            endTime: '10:00',
          ),
          ScheduleSlot(
            courseId: '2',
            courseName: 'Data Structures',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '1',
            roomName: 'Room A1',
            classId: '1',
            className: 'Level 300',
            day: 'Tuesday',
            startTime: '08:00',
            endTime: '10:00',
          ),
        ],
      );

      expect(ga.calculateFitness(timetable), 0);
    });
  });

  group('Population Generator Tests', () {
    test('Population has correct size', () {
      final population = ga.generatePopulation(50);
      expect(population.length, 50);
    });

    test('Each timetable has correct number of slots', () {
      final population = ga.generatePopulation(10);
      for (var timetable in population) {
        expect(timetable.slots.length, courses.length);
      }
    });
  });

  group('Selection Tests', () {
    test('Selection returns half the population', () {
      final population = ga.generatePopulation(100);
      final selected = ga.selection(population);
      expect(selected.length, 50);
    });

    test('Selected timetables are sorted by fitness score', () {
      final population = ga.generatePopulation(100);
      final selected = ga.selection(population);
      for (int i = 0; i < selected.length - 1; i++) {
        expect(
          selected[i].fitnessScore,
          lessThanOrEqualTo(selected[i + 1].fitnessScore),
        );
      }
    });
  });

  group('Crossover Tests', () {
    test('Child has same number of slots as parents', () {
      final parent1 = ga.generateRandomTimetable();
      final parent2 = ga.generateRandomTimetable();
      final child = ga.crossover(parent1, parent2);
      expect(child.slots.length, parent1.slots.length);
    });

    test('Child first half comes from parent1', () {
      final parent1 = ga.generateRandomTimetable();
      final parent2 = ga.generateRandomTimetable();
      final child = ga.crossover(parent1, parent2);
      final midpoint = parent1.slots.length ~/ 2;
      for (int i = 0; i < midpoint; i++) {
        expect(child.slots[i].courseId, parent1.slots[i].courseId);
      }
    });
  });

  group('Soft Constraint Tests', () {
    test('Weekend slots are penalised', () {
      final timetable = Timetable(
        slots: [
          ScheduleSlot(
            courseId: '1',
            courseName: 'Computer Networks',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '1',
            roomName: 'Room A1',
            classId: '1',
            className: 'Level 300',
            day: 'Saturday',
            startTime: '08:00',
            endTime: '10:00',
          ),
        ],
      );
      expect(ga.calculateSoftConstraints(timetable), greaterThan(0));
    });

    test('Weekday slots within school hours have no penalty', () {
      final timetable = Timetable(
        slots: [
          ScheduleSlot(
            courseId: '1',
            courseName: 'Computer Networks',
            lecturerId: '1',
            lecturerName: 'Dr. John Smith',
            roomId: '1',
            roomName: 'Room A1',
            classId: '1',
            className: 'Level 300',
            day: 'Monday',
            startTime: '09:00',
            endTime: '10:00',
          ),
        ],
      );
      expect(ga.calculateSoftConstraints(timetable), 0);
    });
  });
  group('Mutation Tests', () {
    test('Mutated timetable still has correct number of slots', () {
      final timetable = ga.generateRandomTimetable();
      final originalLength = timetable.slots.length;
      ga.mutate(timetable);
      expect(timetable.slots.length, originalLength);
    });

    test('Mutated timetable slots still have required fields', () {
      final timetable = ga.generateRandomTimetable();
      ga.mutate(timetable);
      for (var slot in timetable.slots) {
        expect(slot.courseId, isNotEmpty);
        expect(slot.lecturerId, isNotEmpty);
        expect(slot.roomId, isNotEmpty);
        expect(slot.classId, isNotEmpty);
        expect(slot.day, isNotEmpty);
        expect(slot.startTime, isNotEmpty);
        expect(slot.endTime, isNotEmpty);
      }
    });
  });
}
