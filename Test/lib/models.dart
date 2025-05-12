class Student {
  int id;
  String name;
  Student(this.id, this.name);
  @override
  String toString() => "ID: $id, Name: $name";
}

class Instructor {
  int id;
  String name;
  Instructor(this.id, this.name);
  @override
  String toString() => "ID: $id, Name: $name";
}

class Course {
  int id;
  String name;
  Course(this.id, this.name);
  @override
  String toString() => "ID: $id, Name: $name";
}

class Classroom {
  int id;
  String name;
  int capacity;
  Classroom(this.id, this.name, this.capacity);
  @override
  String toString() => "ID: $id, Name: $name, Capacity: $capacity";
}

class SubjectOffering {
  int id;
  Course course;
  Instructor instructor;
  List<Student> studentsEnrolled;

  SubjectOffering(this.id, this.course, this.instructor, this.studentsEnrolled);

  @override
  String toString() {
    var studentNames = studentsEnrolled.map((s) => s.name).join(', ');
    if (studentNames.isEmpty) studentNames = "None";
    return "Offering ID: $id, Course: ${course.name}, Instructor: ${instructor.name}, Students: $studentNames";
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

  @override
  String toString() {
    return """
  Offering ID: $offeringId
    Course:     $courseName
    Instructor: $instructorName
    Classroom:  $classroomName
    Timeslot:   $timeslot
    Students:   ${studentNames.join(', ')}
    --------------------""";
  }
}