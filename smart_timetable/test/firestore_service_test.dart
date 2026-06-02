import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:smart_timetable/models/timetable_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Firestore Timetable Tests', () {
    test('Save and fetch timetable returns correct slots', () async {
      // Create a test timetable
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
            day: 'Tuesday',
            startTime: '10:00',
            endTime: '12:00',
          ),
        ],
      );

      // Save timetable to fake Firestore
      for (var slot in timetable.slots) {
        await fakeFirestore.collection('timetables').add(slot.toMap());
      }

      // Fetch back from fake Firestore
      final snapshot = await fakeFirestore.collection('timetables').get();
      final fetchedSlots = snapshot.docs
          .map((doc) => ScheduleSlot.fromMap(doc.data()))
          .toList();

      expect(fetchedSlots.length, 2);
      expect(fetchedSlots[0].courseName, 'Computer Networks');
      expect(fetchedSlots[1].courseName, 'Data Structures');
    });

    test('Fetch lecturer timetable returns only their slots', () async {
      // Save two slots for different lecturers
      await fakeFirestore.collection('timetables').add({
        'courseId': '1',
        'courseName': 'Computer Networks',
        'lecturerId': 'lecturer_1',
        'lecturerName': 'Dr. John Smith',
        'roomId': '1',
        'roomName': 'Room A1',
        'classId': '1',
        'className': 'Level 300',
        'day': 'Monday',
        'startTime': '08:00',
        'endTime': '10:00',
      });

      await fakeFirestore.collection('timetables').add({
        'courseId': '2',
        'courseName': 'Data Structures',
        'lecturerId': 'lecturer_2',
        'lecturerName': 'Dr. Jane Doe',
        'roomId': '2',
        'roomName': 'Room B2',
        'classId': '2',
        'className': 'Level 400',
        'day': 'Tuesday',
        'startTime': '10:00',
        'endTime': '12:00',
      });

      // Fetch only lecturer_1 slots
      final snapshot = await fakeFirestore
          .collection('timetables')
          .where('lecturerId', isEqualTo: 'lecturer_1')
          .get();
      final slots = snapshot.docs
          .map((doc) => ScheduleSlot.fromMap(doc.data()))
          .toList();

      expect(slots.length, 1);
      expect(slots[0].lecturerName, 'Dr. John Smith');
    });

    test('Clearing timetable removes all slots', () async {
      // Add some slots
      await fakeFirestore.collection('timetables').add({
        'courseId': '1',
        'courseName': 'Test',
      });
      await fakeFirestore.collection('timetables').add({
        'courseId': '2',
        'courseName': 'Test 2',
      });

      // Clear all
      final existing = await fakeFirestore.collection('timetables').get();
      for (var doc in existing.docs) {
        await doc.reference.delete();
      }

      // Verify empty
      final snapshot = await fakeFirestore.collection('timetables').get();
      expect(snapshot.docs.length, 0);
    });

    test('ScheduleSlot toMap and fromMap are consistent', () {
      final slot = ScheduleSlot(
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
      );

      final map = slot.toMap();
      final restored = ScheduleSlot.fromMap(map);

      expect(restored.courseId, slot.courseId);
      expect(restored.courseName, slot.courseName);
      expect(restored.lecturerId, slot.lecturerId);
      expect(restored.day, slot.day);
      expect(restored.startTime, slot.startTime);
      expect(restored.endTime, slot.endTime);
    });

    test('fromMap handles null values gracefully', () {
      final slot = ScheduleSlot.fromMap({
        'courseId': null,
        'courseName': null,
        'lecturerId': null,
        'lecturerName': null,
        'roomId': null,
        'roomName': null,
        'classId': null,
        'className': null,
        'day': null,
        'startTime': null,
        'endTime': null,
      });

      expect(slot.courseId, '');
      expect(slot.courseName, '');
      expect(slot.day, '');
      expect(slot.startTime, '');
    });
  });
}
