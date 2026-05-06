class ScheduleSlot {
  String courseId;
  String courseName;
  String lecturerId;
  String lecturerName;
  String roomId;
  String roomName;
  String classId;
  String className;
  String day;
  String startTime;
  String endTime;

  ScheduleSlot({
    required this.courseId,
    required this.courseName,
    required this.lecturerId,
    required this.lecturerName,
    required this.roomId,
    required this.roomName,
    required this.classId,
    required this.className,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  // Convert to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'roomId': roomId,
      'roomName': roomName,
      'classId': classId,
      'className': className,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  // Create a ScheduleSlot from a Firestore document
  factory ScheduleSlot.fromMap(Map<String, dynamic> map) {
    return ScheduleSlot(
      courseId: map['courseId'],
      courseName: map['courseName'],
      lecturerId: map['lecturerId'],
      lecturerName: map['lecturerName'],
      roomId: map['roomId'],
      roomName: map['roomName'],
      classId: map['classId'],
      className: map['className'],
      day: map['day'],
      startTime: map['startTime'],
      endTime: map['endTime'],
    );
  }
}

class Timetable {
  List<ScheduleSlot> slots;
  int fitnessScore;

  Timetable({
    required this.slots,
    this.fitnessScore = 0,
  });
}