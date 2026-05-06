import 'dart:math';
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
  });

  // Generate one random timetable
  Timetable generateRandomTimetable() {
    List<ScheduleSlot> slots = [];

    for (var course in courses) {
      // Pick a random lecturer, room, class and timeslot for each course
      var lecturer = lecturers[_random.nextInt(lecturers.length)];
      var room = rooms[_random.nextInt(rooms.length)];
      var cls = classes[_random.nextInt(classes.length)];
      var timeslot = timeslots[_random.nextInt(timeslots.length)];

      slots.add(ScheduleSlot(
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
      ));
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

        bool sameTime = a.day == b.day &&
            a.startTime == b.startTime;

        // Same lecturer teaching two courses at the same time
        if (sameTime && a.lecturerId == b.lecturerId) {
          conflicts++;
        }

        // Same room used by two courses at the same time
        if (sameTime && a.roomId == b.roomId) {
          conflicts++;
        }

        // Same class scheduled for two courses at the same time
        if (sameTime && a.classId == b.classId) {
          conflicts++;
        }
      }
    }

    return conflicts;
  }

// Soft constraints — higher penalty = worse timetable
  int calculateSoftConstraints(Timetable timetable) {
    int penalty = 0;

    for (var slot in timetable.slots) {
      // Penalise lectures scheduled very early (before 8am)
      if (slot.startTime.compareTo('08:00') < 0) {
        penalty++;
      }

      // Penalise lectures scheduled very late (after 6pm)
      if (slot.startTime.compareTo('18:00') > 0) {
        penalty++;
      }

      // Penalise weekend scheduling
      if (slot.day == 'Saturday' || slot.day == 'Sunday') {
        penalty++;
      }
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
    // Score every timetable first
    for (var timetable in population) {
      timetable.fitnessScore = totalScore(timetable);
    }

    // Sort ascending — lowest score (fewest conflicts) comes first
    population.sort((a, b) => a.fitnessScore.compareTo(b.fitnessScore));

    // Keep only the top 50%
    return population.sublist(0, (population.length / 2).floor());
  }

  // Combine two parent timetables to produce a child timetable
  Timetable crossover(Timetable parent1, Timetable parent2) {
    List<ScheduleSlot> childSlots = [];

    // Split point — halfway through the slots
    int midpoint = parent1.slots.length ~/ 2;

    // Take first half from parent1
    for (int i = 0; i < midpoint; i++) {
      childSlots.add(ScheduleSlot(
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
      ));
    }

    // Take second half from parent2
    for (int i = midpoint; i < parent2.slots.length; i++) {
      childSlots.add(ScheduleSlot(
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
      ));
    }

    return Timetable(slots: childSlots);
  }

  // Randomly mutate one slot in a timetable
  void mutate(Timetable timetable) {
    // Only mutate 20% of the time
    if (_random.nextDouble() > 0.2) return;

    // Pick a random slot to mutate
    int index = _random.nextInt(timetable.slots.length);
    ScheduleSlot slot = timetable.slots[index];

    // Randomly change one of four things about that slot
    int mutation = _random.nextInt(4);

    switch (mutation) {
      case 0:
        // Assign a different random lecturer
        var newLecturer = lecturers[_random.nextInt(lecturers.length)];
        slot.lecturerId = newLecturer['id'];
        slot.lecturerName = newLecturer['name'];
        break;
      case 1:
        // Assign a different random room
        var newRoom = rooms[_random.nextInt(rooms.length)];
        slot.roomId = newRoom['id'];
        slot.roomName = newRoom['name'];
        break;
      case 2:
        // Assign a different random timeslot
        var newTimeslot = timeslots[_random.nextInt(timeslots.length)];
        slot.day = newTimeslot['day'];
        slot.startTime = newTimeslot['startTime'];
        slot.endTime = newTimeslot['endTime'];
        break;
      case 3:
        // Assign a different random class
        var newClass = classes[_random.nextInt(classes.length)];
        slot.classId = newClass['id'];
        slot.className = newClass['name'];
        break;
    }
  }

  // Main GA loop — runs everything together
  Future<Timetable> run({int populationSize = 100, int maxGenerations = 500}) async {
    // Step 1 — Generate initial random population
    List<Timetable> population = generatePopulation(populationSize);

    Timetable best = population.first;

    for (int generation = 0; generation < maxGenerations; generation++) {
      // Step 2 — Select the best half
      List<Timetable> selected = selection(population);

      // Step 3 — Update best timetable found so far
      if (selected.first.fitnessScore < best.fitnessScore) {
        best = selected.first;
      }

      // Step 4 — If perfect timetable found stop early
      if (best.fitnessScore == 0) {
        print('Perfect timetable found at generation $generation!');
        break;
      }

      // Step 5 — Breed new generation from top performers
      List<Timetable> newGeneration = List.from(selected);
      while (newGeneration.length < populationSize) {
        Timetable parent1 = selected[_random.nextInt(selected.length)];
        Timetable parent2 = selected[_random.nextInt(selected.length)];
        Timetable child = crossover(parent1, parent2);
        mutate(child);
        newGeneration.add(child);
      }

      population = newGeneration;

      // Log progress every 50 generations
      if (generation % 50 == 0) {
        print('Generation $generation — best score: ${best.fitnessScore}');
      }
    }

    print('GA finished — final score: ${best.fitnessScore}');
    return best;
  }

}