import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/timetable_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveTimetable(Timetable timetable) async {
    try {
      final existing = await _db.collection('timetables').get();
      for (var doc in existing.docs) {
        await doc.reference.delete();
      }
      for (var slot in timetable.slots) {
        await _db.collection('timetables').add(slot.toMap());
      }
      debugPrint('Timetable saved successfully!');
    } catch (e) {
      debugPrint('Error saving timetable: $e');
      rethrow;
    }
  }

  Future<List<ScheduleSlot>> fetchTimetable() async {
    try {
      final snapshot = await _db.collection('timetables').get();
      return snapshot.docs
          .map((doc) => ScheduleSlot.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching timetable: $e');
      return [];
    }
  }

  Future<List<ScheduleSlot>> fetchLecturerTimetable(String lecturerId) async {
    try {
      final snapshot = await _db
          .collection('timetables')
          .where('lecturerId', isEqualTo: lecturerId)
          .get();
      return snapshot.docs
          .map((doc) => ScheduleSlot.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching lecturer timetable: $e');
      return [];
    }
  }
}
