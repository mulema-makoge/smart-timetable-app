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

  // Null-safe fromMap
  factory ScheduleSlot.fromMap(Map<String, dynamic> map) {
    return ScheduleSlot(
      courseId: map['courseId'] as String? ?? '',
      courseName: map['courseName'] as String? ?? '',
      lecturerId: map['lecturerId'] as String? ?? '',
      lecturerName: map['lecturerName'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      roomName: map['roomName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      day: map['day'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
    );
  }
}

class Timetable {
  List<ScheduleSlot> slots;
  int fitnessScore;

  Timetable({required this.slots, this.fitnessScore = 0});
}
