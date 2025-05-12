// lib/providers/scheduler_provider.dart
import 'package:flutter/foundation.dart';
import '../models/timetable_entities.dart';

class SchedulerProvider with ChangeNotifier {
  final List<Student> _students = [];
  final List<Instructor> _instructors = [];
  final List<Course> _courses = [];
  final List<Classroom> _classrooms = [];
  final List<String> _timeslots = [];
  final List<SubjectOffering> _subjectOfferingsToSchedule = [];
  List<ScheduledClass> _finalSchedule = [];
  List<String> _unscheduledMessages = [];

  // Getters for UI to access data
  List<Student> get students => List.unmodifiable(_students);
  List<Instructor> get instructors => List.unmodifiable(_instructors);
  List<Course> get courses => List.unmodifiable(_courses);
  List<Classroom> get classrooms => List.unmodifiable(_classrooms);
  List<String> get timeslots => List.unmodifiable(_timeslots);
  List<SubjectOffering> get subjectOfferingsToSchedule =>
      List.unmodifiable(_subjectOfferingsToSchedule);
  List<ScheduledClass> get finalSchedule => List.unmodifiable(_finalSchedule);
  List<String> get unscheduledMessages =>
      List.unmodifiable(_unscheduledMessages);

  int _nextStudentId = 1;
  int _nextInstructorId = 1;
  int _nextCourseId = 1;
  int _nextClassroomId = 1;
  int _nextOfferingId = 1;

  // --- Helper Methods for ID Generation ---
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

  // --- Add Methods ---
  void addStudent(String name) {
    if (name.trim().isEmpty) return;
    _students.add(Student(_generateIdFor('student'), name.trim()));
    notifyListeners();
  }

  void addInstructor(String name) {
    if (name.trim().isEmpty) return;
    _instructors.add(Instructor(_generateIdFor('instructor'), name.trim()));
    notifyListeners();
  }

  void addCourse(String name) {
    if (name.trim().isEmpty) return;
    _courses.add(Course(_generateIdFor('course'), name.trim()));
    notifyListeners();
  }

  void addClassroom(String name, int capacity) {
    if (name.trim().isEmpty || capacity <= 0) return;
    _classrooms.add(
      Classroom(_generateIdFor('classroom'), name.trim(), capacity),
    );
    notifyListeners();
  }

  void addTimeslot(String timeslot) {
    if (timeslot.trim().isEmpty || _timeslots.contains(timeslot.trim())) return;
    _timeslots.add(timeslot.trim());
    notifyListeners();
  }

  String? addSubjectOffering(
    Course course,
    Instructor instructor,
    List<Student> enrolledStudents,
  ) {
    final offering = SubjectOffering(
      _generateIdFor('offering'),
      course,
      instructor,
      enrolledStudents,
    );
    _subjectOfferingsToSchedule.add(offering);
    notifyListeners();
    return null; // Or an error message if validation fails
  }

  // --- Scheduling Logic ---
  String? _checkForConflicts(
    SubjectOffering offeringToCheck,
    Classroom classroom,
    String timeslot,
  ) {
    if (_finalSchedule.any(
      (sc) => sc.classroomName == classroom.name && sc.timeslot == timeslot,
    )) {
      return "Classroom ${classroom.name} busy at $timeslot.";
    }
    if (_finalSchedule.any(
      (sc) =>
          sc.instructorName == offeringToCheck.instructor.name &&
          sc.timeslot == timeslot,
    )) {
      return "Instructor ${offeringToCheck.instructor.name} busy at $timeslot.";
    }
    for (var student in offeringToCheck.studentsEnrolled) {
      if (_finalSchedule.any(
        (sc) =>
            sc.studentNames.contains(student.name) && sc.timeslot == timeslot,
      )) {
        return "Student ${student.name} busy at $timeslot.";
      }
    }
    if (offeringToCheck.studentsEnrolled.length > classroom.capacity) {
      return "Classroom ${classroom.name} capacity (${classroom.capacity}) too small for ${offeringToCheck.studentsEnrolled.length} students.";
    }
    if (_finalSchedule.any((sc) => sc.offeringId == offeringToCheck.id)) {
      return "Error: Offering ID ${offeringToCheck.id} is somehow already in the final schedule.";
    }
    return null;
  }

  Map<String, dynamic> runScheduler() {
    _finalSchedule.clear();
    _unscheduledMessages.clear();
    Set<int> processedOfferingIds = {};
    int scheduledCount = 0;

    if (_subjectOfferingsToSchedule.isEmpty) {
      _unscheduledMessages.add(
        "No subject offerings in the queue to schedule.",
      );
      notifyListeners();
      return {'scheduled': scheduledCount, 'total': 0};
    }
    if (_classrooms.isEmpty) {
      _unscheduledMessages.add("No classrooms available.");
      notifyListeners();
      return {
        'scheduled': scheduledCount,
        'total': _subjectOfferingsToSchedule.length,
      };
    }
    if (_timeslots.isEmpty) {
      _unscheduledMessages.add("No timeslots available.");
      notifyListeners();
      return {
        'scheduled': scheduledCount,
        'total': _subjectOfferingsToSchedule.length,
      };
    }

    for (var currentOffering in _subjectOfferingsToSchedule) {
      if (processedOfferingIds.contains(currentOffering.id)) continue;

      bool scheduledThisOffering = false;
      String lastConflictReason = "No suitable slot found.";

      for (var classroom in _classrooms) {
        for (var timeslot in _timeslots) {
          String? conflictReason = _checkForConflicts(
            currentOffering,
            classroom,
            timeslot,
          );
          if (conflictReason == null) {
            _finalSchedule.add(
              ScheduledClass(
                currentOffering.id,
                currentOffering.course.name,
                currentOffering.instructor.name,
                currentOffering.studentsEnrolled.map((s) => s.name).toList(),
                classroom.name,
                timeslot,
              ),
            );
            scheduledThisOffering = true;
            scheduledCount++;
            processedOfferingIds.add(currentOffering.id);
            break;
          } else {
            lastConflictReason = conflictReason;
          }
        }
        if (scheduledThisOffering) break;
      }

      if (!scheduledThisOffering) {
        _unscheduledMessages.add(
          "Could not schedule '${currentOffering.course.name}' (ID: ${currentOffering.id}): $lastConflictReason",
        );
      }
    }
    notifyListeners();
    return {
      'scheduled': scheduledCount,
      'total': _subjectOfferingsToSchedule.length,
    };
  }
}
