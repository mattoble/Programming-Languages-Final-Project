// lib/screens/main_scheduler_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scheduler_provider.dart';
import '../models/timetable_entities.dart'; // Assuming your models are here

class MainSchedulerScreen extends StatefulWidget {
  @override
  _MainSchedulerScreenState createState() => _MainSchedulerScreenState();
}

class _MainSchedulerScreenState extends State<MainSchedulerScreen> {
  // Controllers for text fields
  final _studentNameController = TextEditingController();
  final _instructorNameController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _classroomNameController = TextEditingController();
  final _classroomCapacityController = TextEditingController();
  final _timeslotController = TextEditingController();

  // For Create Offering
  Course? _selectedCourseForOffering;
  Instructor? _selectedInstructorForOffering;
  final Set<Student> _selectedStudentsForOffering = {};

  @override
  void dispose() {
    _studentNameController.dispose();
    _instructorNameController.dispose();
    _courseNameController.dispose();
    _classroomNameController.dispose();
    _classroomCapacityController.dispose();
    _timeslotController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  Widget _buildTextFieldWithButton({
    required TextEditingController controller,
    required String labelText,
    required String buttonText,
    required VoidCallback onButtonPressed,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final formKey = GlobalKey<FormState>();
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: labelText,
                  border: OutlineInputBorder(),
                ),
                keyboardType: keyboardType,
                validator:
                    validator ??
                    (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter $labelText';
                      }
                      return null;
                    },
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  onButtonPressed();
                  controller.clear(); // Clear after successful submission
                }
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection<T>({
    required String title,
    required List<T> items,
    required Widget Function(T item) itemBuilder,
    bool initiallyExpanded = false,
  }) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: initiallyExpanded,
      children:
          items.isEmpty
              ? [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No $title added yet.'),
                ),
              ]
              : items.map((item) => itemBuilder(item)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduler = Provider.of<SchedulerProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('All-in-One Timetable Scheduler')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Students Section ---
            _buildListSection<Student>(
              title: 'Students (${scheduler.students.length})',
              items: scheduler.students,
              itemBuilder:
                  (student) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(student.id.toString())),
                      title: Text(student.name),
                    ),
                  ),
            ),
            _buildTextFieldWithButton(
              controller: _studentNameController,
              labelText: 'Student Name',
              buttonText: 'Add Student',
              onButtonPressed: () {
                scheduler.addStudent(_studentNameController.text);
                _showSnackbar('Student added');
              },
            ),
            Divider(height: 30, thickness: 1),

            // --- Instructors Section ---
            _buildListSection<Instructor>(
              title: 'Instructors (${scheduler.instructors.length})',
              items: scheduler.instructors,
              itemBuilder:
                  (instructor) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(instructor.id.toString()),
                      ),
                      title: Text(instructor.name),
                    ),
                  ),
            ),
            _buildTextFieldWithButton(
              controller: _instructorNameController,
              labelText: 'Instructor Name',
              buttonText: 'Add Instructor',
              onButtonPressed: () {
                scheduler.addInstructor(_instructorNameController.text);
                _showSnackbar('Instructor added');
              },
            ),
            Divider(height: 30, thickness: 1),

            // --- Courses Section ---
            _buildListSection<Course>(
              title: 'Courses (${scheduler.courses.length})',
              items: scheduler.courses,
              itemBuilder:
                  (course) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(course.id.toString())),
                      title: Text(course.name),
                    ),
                  ),
            ),
            _buildTextFieldWithButton(
              controller: _courseNameController,
              labelText: 'Course Name',
              buttonText: 'Add Course',
              onButtonPressed: () {
                scheduler.addCourse(_courseNameController.text);
                _showSnackbar('Course added');
              },
            ),
            Divider(height: 30, thickness: 1),

            // --- Classrooms Section ---
            _buildListSection<Classroom>(
              title: 'Classrooms (${scheduler.classrooms.length})',
              items: scheduler.classrooms,
              itemBuilder:
                  (classroom) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(classroom.id.toString()),
                      ),
                      title: Text(classroom.name),
                      subtitle: Text('Capacity: ${classroom.capacity}'),
                    ),
                  ),
            ),
            // Form for Classroom (Name and Capacity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _classroomNameController,
                      decoration: InputDecoration(
                        labelText: 'Classroom Name',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _classroomCapacityController,
                      decoration: InputDecoration(
                        labelText: 'Capacity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null ||
                            int.parse(v.trim()) <= 0)
                          return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Basic validation for demo, ideally use a Form widget
                      if (_classroomNameController.text.isNotEmpty &&
                          _classroomCapacityController.text.isNotEmpty &&
                          int.tryParse(_classroomCapacityController.text) !=
                              null &&
                          int.parse(_classroomCapacityController.text) > 0) {
                        scheduler.addClassroom(
                          _classroomNameController.text,
                          int.parse(_classroomCapacityController.text),
                        );
                        _classroomNameController.clear();
                        _classroomCapacityController.clear();
                        _showSnackbar('Classroom added');
                      } else {
                        _showSnackbar('Invalid classroom input');
                      }
                    },
                    child: Text('Add'),
                  ),
                ],
              ),
            ),
            Divider(height: 30, thickness: 1),

            // --- Timeslots Section ---
            _buildListSection<String>(
              title: 'Timeslots (${scheduler.timeslots.length})',
              items: scheduler.timeslots,
              itemBuilder:
                  (timeslot) => Card(child: ListTile(title: Text(timeslot))),
            ),
            _buildTextFieldWithButton(
              controller: _timeslotController,
              labelText: 'Timeslot (e.g., Mon 09:00-10:00)',
              buttonText: 'Add Timeslot',
              onButtonPressed: () {
                scheduler.addTimeslot(_timeslotController.text);
                _showSnackbar('Timeslot added');
              },
            ),
            Divider(height: 30, thickness: 1),

            // --- Create Subject Offering Section ---
            ExpansionTile(
              title: Text(
                'Create Subject Offering (${scheduler.subjectOfferingsToSchedule.length} queued)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: true,
              children: [
                if (scheduler.courses.isNotEmpty)
                  DropdownButtonFormField<Course>(
                    decoration: InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCourseForOffering,
                    items:
                        scheduler.courses.map((Course course) {
                          return DropdownMenuItem<Course>(
                            value: course,
                            child: Text(course.name),
                          );
                        }).toList(),
                    onChanged:
                        (Course? newValue) => setState(
                          () => _selectedCourseForOffering = newValue,
                        ),
                    validator: (v) => v == null ? 'Required' : null,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Add courses first.'),
                  ),
                SizedBox(height: 10),

                if (scheduler.instructors.isNotEmpty)
                  DropdownButtonFormField<Instructor>(
                    decoration: InputDecoration(
                      labelText: 'Select Instructor',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedInstructorForOffering,
                    items:
                        scheduler.instructors.map((Instructor i) {
                          return DropdownMenuItem<Instructor>(
                            value: i,
                            child: Text(i.name),
                          );
                        }).toList(),
                    onChanged:
                        (Instructor? newValue) => setState(
                          () => _selectedInstructorForOffering = newValue,
                        ),
                    validator: (v) => v == null ? 'Required' : null,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Add instructors first.'),
                  ),
                SizedBox(height: 10),

                Text(
                  'Select Students for Offering (Optional):',
                  style: TextStyle(fontSize: 16),
                ),
                if (scheduler.students.isNotEmpty)
                  Container(
                    height: 150, // Constrain height
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ListView(
                      children:
                          scheduler.students.map((student) {
                            return CheckboxListTile(
                              title: Text(student.name),
                              value: _selectedStudentsForOffering.contains(
                                student,
                              ),
                              onChanged: (bool? selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedStudentsForOffering.add(student);
                                  } else {
                                    _selectedStudentsForOffering.remove(
                                      student,
                                    );
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Add students to select them.'),
                  ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedCourseForOffering != null &&
                        _selectedInstructorForOffering != null) {
                      scheduler.addSubjectOffering(
                        _selectedCourseForOffering!,
                        _selectedInstructorForOffering!,
                        _selectedStudentsForOffering.toList(),
                      );
                      setState(() {
                        // Reset form fields for offering
                        _selectedCourseForOffering = null;
                        _selectedInstructorForOffering = null;
                        _selectedStudentsForOffering.clear();
                      });
                      _showSnackbar('Offering added to queue');
                    } else {
                      _showSnackbar(
                        'Please select course and instructor for offering.',
                      );
                    }
                  },
                  child: Text('Add Offering to Queue'),
                ),
                SizedBox(height: 10),
                _buildListSection<SubjectOffering>(
                  title: 'Queued Offerings',
                  items: scheduler.subjectOfferingsToSchedule,
                  itemBuilder:
                      (offering) => Card(
                        child: ListTile(
                          title: Text(
                            '${offering.course.name} by ${offering.instructor.name}',
                          ),
                          subtitle: Text(
                            'Students: ${offering.studentsSummary}',
                          ),
                        ),
                      ),
                ),
              ],
            ),
            Divider(height: 30, thickness: 1),

            // --- Run Scheduler and View Schedule ---
            ElevatedButton.icon(
              icon: Icon(Icons.schedule_send),
              label: Text('RUN SCHEDULER'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () async {
                final result = scheduler.runScheduler();
                final unscheduledMessages = scheduler.unscheduledMessages;

                await showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: Text('Scheduler Run Complete'),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              Text(
                                'Scheduled ${result['scheduled']} out of ${result['total']} offerings.',
                              ),
                              if (unscheduledMessages.isNotEmpty) ...[
                                SizedBox(height: 10),
                                Text(
                                  'Details for Unscheduled:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...unscheduledMessages.map(
                                  (msg) => Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '- $msg',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('OK'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                );
              },
            ),
            SizedBox(height: 20),
            _buildListSection<ScheduledClass>(
              title: 'Final Schedule (${scheduler.finalSchedule.length})',
              initiallyExpanded: true, // Often want to see this
              items: scheduler.finalSchedule,
              itemBuilder:
                  (scheduledClass) => Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scheduledClass.courseName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 4),
                          Text('Instructor: ${scheduledClass.instructorName}'),
                          Text('Classroom: ${scheduledClass.classroomName}'),
                          Text('Timeslot: ${scheduledClass.timeslot}'),
                          SizedBox(height: 4),
                          Text(
                            'Students: ${scheduledClass.studentNames.join(', ')}',
                          ),
                          Text(
                            'Offering ID: ${scheduledClass.offeringId}',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
