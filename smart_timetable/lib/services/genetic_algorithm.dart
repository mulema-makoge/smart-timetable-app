import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/timetable_model.dart';

class GeneticAlgorithm {
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> lecturers;
  final List<Map<String, dynamic>> rooms;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> timeslots;

  final Random _random = Random();

  GeneticAlgorithm({
    required this.courses,
    required this.lecturers,
    required this.rooms,
    required this.classes,
    required this.timeslots,
  }) {
    assert(courses.isNotEmpty, 'Courses list cannot be empty');
    assert(lecturers.isNotEmpty, 'Lecturers list cannot be empty');
    assert(rooms.isNotEmpty, 'Rooms list cannot be empty');
    assert(classes.isNotEmpty, 'Classes list cannot be empty');
    assert(timeslots.isNotEmpty, 'Timeslots list cannot be empty');
  }

  // Generate one random timetable
  Timetable generateRandomTimetable() {
    List<ScheduleSlot> slots = [];

    for (var course in courses) {
      assert(course.containsKey('id'), 'Course must have an id');
      assert(course.containsKey('name'), 'Course must have a name');

      var lecturer = lecturers[_random.nextInt(lecturers.length)];
      assert(lecturer.containsKey('id'), 'Lecturer must have an id');
      assert(lecturer.containsKey('name'), 'Lecturer must have a name');

      var room = rooms[_random.nextInt(rooms.length)];
      assert(room.containsKey('id'), 'Room must have an id');
      assert(room.containsKey('name'), 'Room must have a name');

      var cls = classes[_random.nextInt(classes.length)];
      assert(cls.containsKey('id'), 'Class must have an id');
      assert(cls.containsKey('name'), 'Class must have a name');

      var timeslot = timeslots[_random.nextInt(timeslots.length)];
      assert(timeslot.containsKey('day'), 'Timeslot must have a day');
      assert(
        timeslot.containsKey('startTime'),
        'Timeslot must have a startTime',
      );
      assert(timeslot.containsKey('endTime'), 'Timeslot must have an endTime');

      slots.add(
        ScheduleSlot(
          courseId: course['id'],
          courseName: course['name'],
          lecturerId: lecturer['id'],
          lecturerName: lecturer['name'],
          roomId: room['id'],
          roomName: room['name'],
          classId: cls['id'],
          className: cls['name'],
          day: timeslot['day'],
          startTime: timeslot['startTime'],
          endTime: timeslot['endTime'],
        ),
      );
    }

    return Timetable(slots: slots);
  }

  // Generate a full population of random timetables
  List<Timetable> generatePopulation(int size) {
    List<Timetable> population = [];
    for (int i = 0; i < size; i++) {
      population.add(generateRandomTimetable());
    }
    return population;
  }

  // Calculate fitness — lower score = better timetable
  int calculateFitness(Timetable timetable) {
    int conflicts = 0;

    for (int i = 0; i < timetable.slots.length; i++) {
      for (int j = i + 1; j < timetable.slots.length; j++) {
        ScheduleSlot a = timetable.slots[i];
        ScheduleSlot b = timetable.slots[j];

        bool sameTime = a.day == b.day && a.startTime == b.startTime;

        if (sameTime && a.lecturerId == b.lecturerId) conflicts++;
        if (sameTime && a.roomId == b.roomId) conflicts++;
        if (sameTime && a.classId == b.classId) conflicts++;
      }
    }

    return conflicts;
  }

  // Soft constraints — higher penalty = worse timetable
  int calculateSoftConstraints(Timetable timetable) {
    int penalty = 0;

    for (var slot in timetable.slots) {
      if (slot.startTime.compareTo('08:00') < 0) penalty++;
      if (slot.startTime.compareTo('18:00') > 0) penalty++;
      if (slot.day == 'Saturday' || slot.day == 'Sunday') penalty++;
    }

    return penalty;
  }

  // Combined score — hard conflicts weighted heavier than soft penalties
  int totalScore(Timetable timetable) {
    int hardScore = calculateFitness(timetable) * 10;
    int softScore = calculateSoftConstraints(timetable);
    return hardScore + softScore;
  }

  // Sort population by total score — lowest score = best timetable
  List<Timetable> selection(List<Timetable> population) {
    for (var timetable in population) {
      timetable.fitnessScore = totalScore(timetable);
    }
    population.sort((a, b) => a.fitnessScore.compareTo(b.fitnessScore));
    return population.sublist(0, (population.length / 2).floor());
  }

  // Combine two parent timetables to produce a child timetable
  Timetable crossover(Timetable parent1, Timetable parent2) {
    List<ScheduleSlot> childSlots = [];
    int midpoint = parent1.slots.length ~/ 2;

    for (int i = 0; i < midpoint; i++) {
      childSlots.add(
        ScheduleSlot(
          courseId: parent1.slots[i].courseId,
          courseName: parent1.slots[i].courseName,
          lecturerId: parent1.slots[i].lecturerId,
          lecturerName: parent1.slots[i].lecturerName,
          roomId: parent1.slots[i].roomId,
          roomName: parent1.slots[i].roomName,
          classId: parent1.slots[i].classId,
          className: parent1.slots[i].className,
          day: parent1.slots[i].day,
          startTime: parent1.slots[i].startTime,
          endTime: parent1.slots[i].endTime,
        ),
      );
    }

    for (int i = midpoint; i < parent2.slots.length; i++) {
      childSlots.add(
        ScheduleSlot(
          courseId: parent2.slots[i].courseId,
          courseName: parent2.slots[i].courseName,
          lecturerId: parent2.slots[i].lecturerId,
          lecturerName: parent2.slots[i].lecturerName,
          roomId: parent2.slots[i].roomId,
          roomName: parent2.slots[i].roomName,
          classId: parent2.slots[i].classId,
          className: parent2.slots[i].className,
          day: parent2.slots[i].day,
          startTime: parent2.slots[i].startTime,
          endTime: parent2.slots[i].endTime,
        ),
      );
    }

    return Timetable(slots: childSlots);
  }

  // Randomly mutate one slot in a timetable
  void mutate(Timetable timetable) {
    if (_random.nextDouble() > 0.2) return;

    int index = _random.nextInt(timetable.slots.length);
    ScheduleSlot slot = timetable.slots[index];
    int mutation = _random.nextInt(4);

    switch (mutation) {
      case 0:
        var newLecturer = lecturers[_random.nextInt(lecturers.length)];
        slot.lecturerId = newLecturer['id'];
        slot.lecturerName = newLecturer['name'];
        break;
      case 1:
        var newRoom = rooms[_random.nextInt(rooms.length)];
        slot.roomId = newRoom['id'];
        slot.roomName = newRoom['name'];
        break;
      case 2:
        var newTimeslot = timeslots[_random.nextInt(timeslots.length)];
        slot.day = newTimeslot['day'];
        slot.startTime = newTimeslot['startTime'];
        slot.endTime = newTimeslot['endTime'];
        break;
      case 3:
        var newClass = classes[_random.nextInt(classes.length)];
        slot.classId = newClass['id'];
        slot.className = newClass['name'];
        break;
    }
  }

  // Main GA loop — returns best timetable and generation count
  Future<({Timetable timetable, int generations})?> run({
    int populationSize = 100,
    int maxGenerations = 500,
  }) async {
    try {
      List<Timetable> population = generatePopulation(populationSize);
      Timetable best = population.first;
      int generationsRun = 0;

      for (int generation = 0; generation < maxGenerations; generation++) {
        generationsRun = generation + 1;

        List<Timetable> selected = selection(population);

        if (selected.first.fitnessScore < best.fitnessScore) {
          best = selected.first;
        }

        if (best.fitnessScore == 0) {
          debugPrint('Perfect timetable found at generation $generation!');
          break;
        }

        List<Timetable> newGeneration = List.from(selected);
        while (newGeneration.length < populationSize) {
          Timetable parent1 = selected[_random.nextInt(selected.length)];
          Timetable parent2 = selected[_random.nextInt(selected.length)];
          Timetable child = crossover(parent1, parent2);
          mutate(child);
          newGeneration.add(child);
        }

        population = newGeneration;

        if (generation % 50 == 0) {
          debugPrint(
            'Generation $generation — best score: ${best.fitnessScore}',
          );
        }
      }

      debugPrint('GA finished — final score: ${best.fitnessScore}');
      return (timetable: best, generations: generationsRun);
    } catch (e) {
      debugPrint('GA error: $e');
      return null;
    }
  }
}
