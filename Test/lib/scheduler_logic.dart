// lib/scheduler_logic.dart
import 'models.dart'; // Import your models

class TimetableScheduler {
  final List<Student> _students = [];
  final List<Instructor> _instructors = [];
  final List<Course> _courses = [];
  final List<Classroom> _classrooms = [];
  final List<String> _timeslots = [];

  final List<SubjectOffering> _subjectOfferingsToSchedule = [];
  List<ScheduledClass> _finalSchedule = [];

  int _nextStudentId = 1;
  int _nextInstructorId = 1;
  int _nextCourseId = 1;
  int _nextClassroomId = 1;
  int _nextOfferingId = 1;

  // --- Public Getters for UI ---
  List<Student> get students => List.unmodifiable(_students);
  List<Instructor> get instructors => List.unmodifiable(_instructors);
  List<Course> get courses => List.unmodifiable(_courses);
  List<Classroom> get classrooms => List.unmodifiable(_classrooms);
  List<String> get timeslots => List.unmodifiable(_timeslots);
  List<SubjectOffering> get subjectOfferingsToSchedule => List.unmodifiable(_subjectOfferingsToSchedule);
  List<ScheduledClass> get finalSchedule => List.unmodifiable(_finalSchedule);


  // --- Helper Methods ---
  int _generateIdFor(String type) {
    switch (type) {
      case 'student': return _nextStudentId++;
      case 'instructor': return _nextInstructorId++;
      case 'course': return _nextCourseId++;
      case 'classroom': return _nextClassroomId++;
      case 'offering': return _nextOfferingId++;
      default: throw ArgumentError("Unknown type for ID generation: $type");
    }
  }

  T? _findById<T extends dynamic>(List<T> collection, int id) {
    try {
      return collection.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- Add Methods ---
  String addStudent(String name) {
    if (name.isEmpty) return "Student name cannot be empty.";
    var student = Student(_generateIdFor('student'), name);
    _students.add(student);
    return "Student '${student.name}' (ID: ${student.id}) added.";
  }

  String addInstructor(String name) {
    if (name.isEmpty) return "Instructor name cannot be empty.";
    var instructor = Instructor(_generateIdFor('instructor'), name);
    _instructors.add(instructor);
    return "Instructor '${instructor.name}' (ID: ${instructor.id}) added.";
  }

  String addCourse(String name) {
    if (name.isEmpty) return "Course name cannot be empty.";
    var course = Course(_generateIdFor('course'), name);
    _courses.add(course);
    return "Course '${course.name}' (ID: ${course.id}) added.";
  }

  String addClassroom(String name, String capacityStr) {
    if (name.isEmpty) return "Classroom name cannot be empty.";
    int? capacity = int.tryParse(capacityStr);
    if (capacity == null || capacity <= 0) {
      return "Invalid capacity. Please enter a positive number.";
    }
    var classroom = Classroom(_generateIdFor('classroom'), name, capacity);
    _classrooms.add(classroom);
    return "Classroom '${classroom.name}' (Capacity: ${classroom.capacity}, ID: ${classroom.id}) added.";
  }

  String addTimeslot(String timeslotStr) {
    if (timeslotStr.isEmpty) return "Timeslot cannot be empty.";
    if (_timeslots.contains(timeslotStr)) return "Timeslot already exists.";
    _timeslots.add(timeslotStr);
    return "Timeslot '$timeslotStr' added.";
  }

  String addSubjectOffering(int courseId, int instructorId, List<int> studentIds) {
    Course? course = _findById(_courses, courseId);
    if (course == null) return "Invalid Course ID.";

    Instructor? instructor = _findById(_instructors, instructorId);
    if (instructor == null) return "Invalid Instructor ID.";

    List<Student> enrolledStudentsList = [];
    for (var sId in studentIds) {
        Student? student = _findById(_students, sId);
        if (student != null && !enrolledStudentsList.contains(student)) {
            enrolledStudentsList.add(student);
        } else if (student == null) {
            return "Invalid Student ID: $sId found during offering creation.";
        }
    }

    var offering = SubjectOffering(
      _generateIdFor('offering'),
      course,
      instructor,
      enrolledStudentsList,
    );
    _subjectOfferingsToSchedule.add(offering);
    return "Subject Offering '${course.name}' by '${instructor.name}' (ID: ${offering.id}) added to scheduling queue.";
  }


  // --- View Methods --- (Not needed, UI will directly access lists via getters)

  // --- Scheduling Logic ---
  String? _checkForConflicts(
    SubjectOffering offeringToCheck,
    Classroom classroom,
    String timeslot,
  ) {
    if (_finalSchedule.any((sc) => sc.classroomName == classroom.name && sc.timeslot == timeslot)) {
      return "Conflict: Classroom ${classroom.name} busy at $timeslot.";
    }
    if (_finalSchedule.any((sc) => sc.instructorName == offeringToCheck.instructor.name && sc.timeslot == timeslot)) {
      return "Conflict: Instructor ${offeringToCheck.instructor.name} busy at $timeslot.";
    }
    for (var student in offeringToCheck.studentsEnrolled) {
      if (_finalSchedule.any((sc) => sc.studentNames.contains(student.name) && sc.timeslot == timeslot)) {
        return "Conflict: Student ${student.name} busy at $timeslot.";
      }
    }
    if (offeringToCheck.studentsEnrolled.length > classroom.capacity) {
      return "Conflict: Classroom ${classroom.name} capacity (${classroom.capacity}) too small for ${offeringToCheck.studentsEnrolled.length} students.";
    }
    if (_finalSchedule.any((sc) => sc.offeringId == offeringToCheck.id)) {
      return "Error: Offering ID ${offeringToCheck.id} is somehow already in the final schedule.";
    }
    return null;
  }

  List<String> runScheduler() { 
    List<String> logMessages = [];
    if (_subjectOfferingsToSchedule.isEmpty) {
      logMessages.add("No subject offerings in the queue to schedule. Please add some first.");
      return logMessages;
    }
    if (_classrooms.isEmpty) {
      logMessages.add("No classrooms available. Please add classrooms first.");
      return logMessages;
    }
    if (_timeslots.isEmpty) {
      logMessages.add("No timeslots available. Please add timeslots first.");
      return logMessages;
    }

    logMessages.add("--- Running Scheduler ---");
    List<ScheduledClass> newSchedule = [];

    Set<int> processedOfferingIds = {};

    for (var currentOffering in _subjectOfferingsToSchedule) {
      if (processedOfferingIds.contains(currentOffering.id)) {
        logMessages.add("Skipping already processed offering ID: ${currentOffering.id}");
        continue;
      }

      logMessages.add(
        "Attempting to schedule: ${currentOffering.course.name} (Instructor: ${currentOffering.instructor.name}, Offering ID: ${currentOffering.id})",
      );
      bool scheduledThisOffering = false;

      for (var classroom in _classrooms) {
        for (var timeslot in _timeslots) {
          // Check conflicts against the newSchedule being built
           String? conflictReason = _checkForConflictsWithTempSchedule(
            currentOffering,
            classroom,
            timeslot,
            newSchedule, 
          );

          if (conflictReason != null) {
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
            newSchedule.add(newScheduledClass); 
            scheduledThisOffering = true;
            processedOfferingIds.add(currentOffering.id);
            logMessages.add(
              "SUCCESS: Scheduled ${currentOffering.course.name} in ${classroom.name} at $timeslot",
            );
            break;
          }
        }
        if (scheduledThisOffering) break;
      }

      if (!scheduledThisOffering) {
        logMessages.add(
          "FAILURE: Could not find a suitable slot for ${currentOffering.course.name} (ID: ${currentOffering.id}).",
        );
      }
    }
    _finalSchedule = List.unmodifiable(newSchedule); // Update the main schedule once done
    logMessages.add("--- Scheduler Finished ---");
    return logMessages;
  }

  // Helper for runScheduler to check against the schedule being built
  String? _checkForConflictsWithTempSchedule(
    SubjectOffering offeringToCheck,
    Classroom classroom,
    String timeslot,
    List<ScheduledClass> tempSchedule, // Check against this schedule
  ) {
    if (tempSchedule.any((sc) => sc.classroomName == classroom.name && sc.timeslot == timeslot)) {
      return "Conflict: Classroom ${classroom.name} busy at $timeslot.";
    }
    if (tempSchedule.any((sc) => sc.instructorName == offeringToCheck.instructor.name && sc.timeslot == timeslot)) {
      return "Conflict: Instructor ${offeringToCheck.instructor.name} busy at $timeslot.";
    }
    for (var student in offeringToCheck.studentsEnrolled) {
      if (tempSchedule.any((sc) => sc.studentNames.contains(student.name) && sc.timeslot == timeslot)) {
        return "Conflict: Student ${student.name} busy at $timeslot.";
      }
    }
    if (offeringToCheck.studentsEnrolled.length > classroom.capacity) {
      return "Conflict: Classroom ${classroom.name} capacity (${classroom.capacity}) too small for ${offeringToCheck.studentsEnrolled.length} students.";
    }
    // Offering ID check is not needed here as we are building a new schedule.
    return null;
  }
}