// lib/models/timetable_entities.dart
class Student {
  int id;
  String name;
  Student(this.id, this.name);
}

class Instructor {
  int id;
  String name;
  Instructor(this.id, this.name);
}

class Course {
  int id;
  String name;
  Course(this.id, this.name);
}

class Classroom {
  int id;
  String name;
  int capacity;
  Classroom(this.id, this.name, this.capacity);
}

class SubjectOffering {
  int id;
  Course course;
  Instructor instructor;
  List<Student> studentsEnrolled;

  SubjectOffering(this.id, this.course, this.instructor, this.studentsEnrolled);

  String get studentsSummary {
    if (studentsEnrolled.isEmpty) return "No students";
    return studentsEnrolled.map((s) => s.name).join(', ');
  }
}

class ScheduledClass {
  int offeringId;
  String courseName;
  String instructorName;
  List<String> studentNames;
  String classroomName;
  String timeslot;

  ScheduledClass(
    this.offeringId,
    this.courseName,
    this.instructorName,
    this.studentNames,
    this.classroomName,
    this.timeslot,
  );
}
