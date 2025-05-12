import 'dart:io';

// --- DATA STRUCTURES ---

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

// Represents the general course, e.g., "CS101"
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

// This is what we actually try to schedule
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

class TimetableScheduler {
  final List<Student> _students = [];
  final List<Instructor> _instructors = [];
  final List<Course> _courses = [];
  final List<Classroom> _classrooms = [];
  final List<String> _timeslots = [];

  final List<SubjectOffering> _subjectOfferingsToSchedule = [];
  List<ScheduledClass> _finalSchedule = []; // Modifiable

  int _nextStudentId = 1;
  int _nextInstructorId = 1;
  int _nextCourseId = 1;
  int _nextClassroomId = 1;
  int _nextOfferingId = 1;

  // --- Helper Methods ---
  String _prompt(String message) {
    stdout.write(message);
    return stdin.readLineSync() ?? "";
  }

  int _generateIdFor(String type) {
    switch (type) {
      case 'student':
        return _nextStudentId++;
      case 'instructor':
        return _nextInstructorId++;
      case 'course':
        return _nextCourseId++;
      case 'classroom':
        return _nextClassroomId++;
      case 'offering':
        return _nextOfferingId++;
      default:
        throw ArgumentError("Unknown type for ID generation: $type");
    }
  }

  T? _findById<T extends dynamic>(List<T> collection, int id) {
    // Assuming items in collection have an 'id' property
    try {
      return collection.firstWhere((item) => item.id == id);
    } catch (e) {
      return null; // Not found
    }
  }

  void _displayList<T>(
    List<T> items,
    String title,
    String Function(T) formatter,
  ) {
    print("\n--- $title ---");
    if (items.isEmpty) {
      print("No ${title.toLowerCase()} available.");
    } else {
      items.asMap().forEach((index, item) {
        // Using item.id if available, otherwise index
        String prefix = "";
        try {
          prefix = "${(item as dynamic).id}. ";
        } catch (e) {
          prefix = "${index + 1}. ";
        }
        print(prefix + formatter(item));
      });
    }
    print("-------------------");
  }

  // --- Add Methods ---
  void addStudent() {
    String name = _prompt("Enter student name: ");
    if (name.isEmpty) {
      print("Student name cannot be empty.");
      return;
    }
    var student = Student(_generateIdFor('student'), name);
    _students.add(student);
    print("Student '${student.name}' (ID: ${student.id}) added.");
  }

  void addInstructor() {
    String name = _prompt("Enter instructor name: ");
    if (name.isEmpty) {
      print("Instructor name cannot be empty.");
      return;
    }
    var instructor = Instructor(_generateIdFor('instructor'), name);
    _instructors.add(instructor);
    print("Instructor '${instructor.name}' (ID: ${instructor.id}) added.");
  }

  void addCourse() {
    String name = _prompt(
      "Enter course name (e.g., CS101 - Intro to Programming): ",
    );
    if (name.isEmpty) {
      print("Course name cannot be empty.");
      return;
    }
    var course = Course(_generateIdFor('course'), name);
    _courses.add(course);
    print("Course '${course.name}' (ID: ${course.id}) added.");
  }

  void addClassroom() {
    String name = _prompt("Enter classroom name (e.g., Room A101): ");
    if (name.isEmpty) {
      print("Classroom name cannot be empty.");
      return;
    }
    String capacityStr = _prompt("Enter classroom capacity: ");
    int? capacity = int.tryParse(capacityStr);
    if (capacity == null || capacity <= 0) {
      print("Invalid capacity. Please enter a positive number.");
      return;
    }
    var classroom = Classroom(_generateIdFor('classroom'), name, capacity);
    _classrooms.add(classroom);
    print(
      "Classroom '${classroom.name}' (Capacity: ${classroom.capacity}, ID: ${classroom.id}) added.",
    );
  }

  void addTimeslot() {
    String timeslotStr = _prompt("Enter timeslot (e.g., Mon 09:00-10:00): ");
    if (timeslotStr.isEmpty) {
      print("Timeslot cannot be empty.");
      return;
    }
    if (_timeslots.contains(timeslotStr)) {
      print("Timeslot already exists.");
    } else {
      _timeslots.add(timeslotStr);
      print("Timeslot '$timeslotStr' added.");
    }
  }

  void addSubjectOfferingToSchedule() {
    if (_courses.isEmpty) {
      print("Please add courses first.");
      return;
    }
    if (_instructors.isEmpty) {
      print("Please add instructors first.");
      return;
    }

    _displayList(_courses, "Available Courses", (c) => c.name);
    String courseIdStr = _prompt("Enter Course ID to offer: ");
    int? courseId = int.tryParse(courseIdStr);
    Course? course = courseId != null ? _findById(_courses, courseId) : null;
    if (course == null) {
      print("Invalid Course ID.");
      return;
    }

    _displayList(_instructors, "Available Instructors", (i) => i.name);
    String instructorIdStr = _prompt("Enter Instructor ID for this offering: ");
    int? instructorId = int.tryParse(instructorIdStr);
    Instructor? instructor =
        instructorId != null ? _findById(_instructors, instructorId) : null;
    if (instructor == null) {
      print("Invalid Instructor ID.");
      return;
    }

    List<Student> enrolledStudentsList = [];
    if (_students.isNotEmpty) {
      while (true) {
        _displayList(_students, "Available Students", (s) => s.name);
        _displayList(
          enrolledStudentsList,
          "Currently Enrolled for this Offering",
          (s) => s.name,
        );
        String studentInput = _prompt(
          "Enter Student ID to enroll (or type 'done'): ",
        );
        if (studentInput.toLowerCase() == 'done') break;

        int? studentId = int.tryParse(studentInput);
        Student? student =
            studentId != null ? _findById(_students, studentId) : null;

        if (student != null && !enrolledStudentsList.contains(student)) {
          enrolledStudentsList.add(student);
          print("${student.name} added to this offering.");
        } else if (enrolledStudentsList.contains(student)) {
          print("${student?.name} is already added.");
        } else {
          print("Invalid Student ID.");
        }
      }
    } else {
      print(
        "No students available to enroll. Offering will have 0 students for now.",
      );
    }

    var offering = SubjectOffering(
      _generateIdFor('offering'),
      course,
      instructor,
      enrolledStudentsList,
    );
    _subjectOfferingsToSchedule.add(offering);
    print(
      "Subject Offering '${course.name}' by '${instructor.name}' (ID: ${offering.id}) added to scheduling queue.",
    );
  }

  // --- View Methods ---
  void viewStudents() => _displayList(_students, "Students", (s) => s.name);
  void viewInstructors() =>
      _displayList(_instructors, "Instructors", (i) => i.name);
  void viewCourses() => _displayList(_courses, "Courses", (c) => c.name);
  void viewClassrooms() => _displayList(
    _classrooms,
    "Classrooms",
    (c) => "${c.name} (Capacity: ${c.capacity})",
  );
  void viewTimeslots() =>
      _displayList(_timeslots, "Available Timeslots", (ts) => ts);

  void viewOfferingsToSchedule() {
    _displayList(_subjectOfferingsToSchedule, "Offerings Queued for Scheduling", (
      offering,
    ) {
      var studentNames = offering.studentsEnrolled
          .map((s) => s.name)
          .join(', ');
      studentNames = studentNames.isEmpty ? "None" : studentNames;
      return "${offering.course.name} - Instructor: ${offering.instructor.name} - Students: $studentNames";
    });
  }

  void viewFinalSchedule() {
    print("\n--- FINAL SCHEDULE ---");
    if (_finalSchedule.isEmpty) {
      print("No classes have been scheduled yet, or scheduling failed.");
    } else {
      _finalSchedule.forEach(print); // Uses ScheduledClass.toString()
    }
    print("--------------------");
  }

  // --- Scheduling Logic ---
  String? _checkForConflicts(
    SubjectOffering offeringToCheck,
    Classroom classroom,
    String timeslot,
  ) {
    // 1. Classroom availability
    if (_finalSchedule.any(
      (sc) => sc.classroomName == classroom.name && sc.timeslot == timeslot,
    )) {
      return "Conflict: Classroom ${classroom.name} busy at $timeslot.";
    }

    // 2. Instructor availability
    if (_finalSchedule.any(
      (sc) =>
          sc.instructorName == offeringToCheck.instructor.name &&
          sc.timeslot == timeslot,
    )) {
      return "Conflict: Instructor ${offeringToCheck.instructor.name} busy at $timeslot.";
    }

    // 3. Student availability
    for (var student in offeringToCheck.studentsEnrolled) {
      if (_finalSchedule.any(
        (sc) =>
            sc.studentNames.contains(student.name) && sc.timeslot == timeslot,
      )) {
        return "Conflict: Student ${student.name} busy at $timeslot.";
      }
    }

    // 4. Classroom capacity
    if (offeringToCheck.studentsEnrolled.length > classroom.capacity) {
      return "Conflict: Classroom ${classroom.name} capacity (${classroom.capacity}) too small for ${offeringToCheck.studentsEnrolled.length} students.";
    }

    // 5. Offering ID already scheduled (should not happen if logic is correct elsewhere but good check)
    if (_finalSchedule.any((sc) => sc.offeringId == offeringToCheck.id)) {
      return "Error: Offering ID ${offeringToCheck.id} is somehow already in the final schedule.";
    }

    return null; // No conflicts
  }

  void runScheduler() {
    if (_subjectOfferingsToSchedule.isEmpty) {
      print(
        "No subject offerings in the queue to schedule. Please add some first.",
      );
      return;
    }
    if (_classrooms.isEmpty) {
      print("No classrooms available. Please add classrooms first.");
      return;
    }
    if (_timeslots.isEmpty) {
      print("No timeslots available. Please add timeslots first.");
      return;
    }

    print("\n--- Running Scheduler ---");
    _finalSchedule.clear(); // Clear previous schedule

    Set<int> processedOfferingIds =
        {}; // To avoid processing the same offering multiple times

    for (var currentOffering in _subjectOfferingsToSchedule) {
      if (processedOfferingIds.contains(currentOffering.id)) {
        print("Skipping already processed offering ID: ${currentOffering.id}");
        continue;
      }

      print(
        "\nAttempting to schedule: ${currentOffering.course.name} (Instructor: ${currentOffering.instructor.name}, Offering ID: ${currentOffering.id})",
      );
      bool scheduledThisOffering = false;

      for (var classroom in _classrooms) {
        for (var timeslot in _timeslots) {
          String? conflictReason = _checkForConflicts(
            currentOffering,
            classroom,
            timeslot,
          );

          if (conflictReason != null) {
            // print("    $conflictReason"); // Verbose logging for debugging
            continue;
          } else {
            var newScheduledClass = ScheduledClass(
              currentOffering.id,
              currentOffering.course.name,
              currentOffering.instructor.name,
              currentOffering.studentsEnrolled.map((s) => s.name).toList(),
              classroom.name,
              timeslot,
            );
            _finalSchedule.add(newScheduledClass);
            scheduledThisOffering = true;
            processedOfferingIds.add(currentOffering.id);
            print(
              "  SUCCESS: Scheduled ${currentOffering.course.name} in ${classroom.name} at $timeslot",
            );
            break; // Break from TIMESLOTS loop
          }
        } // End TIMESLOTS loop
        if (scheduledThisOffering) break; // Break from CLASSROOMS loop
      } // End CLASSROOMS loop

      if (!scheduledThisOffering) {
        print(
          "  FAILURE: Could not find a suitable slot for ${currentOffering.course.name} (ID: ${currentOffering.id}).",
        );
      }
    }
    print("--- Scheduler Finished ---");
    viewFinalSchedule();
  }

  // --- Main Menu ---
  void mainMenu() {
    while (true) {
      print("\n===== Timetable Scheduler Menu (Dart) =====");
      print("1. Add Student");
      print("2. Add Instructor");
      print("3. Add Course (e.g., Math 101)");
      print("4. Add Classroom");
      print("5. Add Timeslot");
      print("6. Create Subject Offering (to be scheduled)");
      print("------------------------------------");
      print("7. View Students");
      print("8. View Instructors");
      print("9. View Courses");
      print("10. View Classrooms");
      print("11. View Timeslots");
      print("12. View Offerings Queued for Scheduling");
      print("------------------------------------");
      print("13. RUN SCHEDULER");
      print("14. View Final Schedule");
      print("------------------------------------");
      print("0. Exit");
      String choice = _prompt("Enter your choice: ");

      switch (choice) {
        case '1':
          addStudent();
          break;
        case '2':
          addInstructor();
          break;
        case '3':
          addCourse();
          break;
        case '4':
          addClassroom();
          break;
        case '5':
          addTimeslot();
          break;
        case '6':
          addSubjectOfferingToSchedule();
          break;
        case '7':
          viewStudents();
          break;
        case '8':
          viewInstructors();
          break;
        case '9':
          viewCourses();
          break;
        case '10':
          viewClassrooms();
          break;
        case '11':
          viewTimeslots();
          break;
        case '12':
          viewOfferingsToSchedule();
          break;
        case '13':
          runScheduler();
          break;
        case '14':
          viewFinalSchedule();
          break;
        case '0':
          print("Exiting. Goodbye!");
          return; // Exit the loop and method
        default:
          print("Invalid choice. Please try again.");
      }
    }
  }
}

void main() {
  var schedulerApp = TimetableScheduler();
  schedulerApp.mainMenu();
}
