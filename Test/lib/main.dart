import 'package:flutter/material.dart';
import 'scheduler_logic.dart';
import 'models.dart';

void main() {
  runApp(const TimetableApp());
}

class TimetableApp extends StatelessWidget {
  const TimetableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timetable Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SchedulerHomePage(),
    );
  }
}

class SchedulerHomePage extends StatefulWidget {
  const SchedulerHomePage({super.key});

  @override
  State<SchedulerHomePage> createState() => _SchedulerHomePageState();
}

class _SchedulerHomePageState extends State<SchedulerHomePage> with SingleTickerProviderStateMixin {
  final TimetableScheduler _scheduler = TimetableScheduler();
  late TabController _tabController;
  List<String> _schedulerLog = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Added a "Schedule" tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // --- Dialogs for Adding Items ---
  Future<void> _showAddSimpleItemDialog(String title, String label, Function(String) onSave) async {
    final controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Add $title'),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  String message = onSave(controller.text);
                  setState(() {}); // Refresh UI
                  _showSnackbar(message);
                  Navigator.of(context).pop();
                } else {
                  _showSnackbar('$label cannot be empty.', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddClassroomDialog() async {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Classroom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Classroom Name'),
                autofocus: true,
              ),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add Classroom'),
              onPressed: () {
                if (nameController.text.isNotEmpty && capacityController.text.isNotEmpty) {
                  String message = _scheduler.addClassroom(nameController.text, capacityController.text);
                  setState(() {});
                  _showSnackbar(message, isError: message.toLowerCase().contains('invalid'));
                  Navigator.of(context).pop();
                } else {
                    _showSnackbar('Name and Capacity cannot be empty.', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSubjectOfferingDialog() async {
    Course? selectedCourse;
    Instructor? selectedInstructor;
    List<Student> selectedStudents = [];

    if (_scheduler.courses.isEmpty || _scheduler.instructors.isEmpty) {
      _showSnackbar("Please add courses and instructors first.", isError: true);
      return;
    }

    // Using StatefulBuilder to manage dialog's own state for selections
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Subject Offering'),
              content: SingleChildScrollView( // In case of many students
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DropdownButtonFormField<Course>(
                      decoration: const InputDecoration(labelText: 'Select Course'),
                      value: selectedCourse,
                      items: _scheduler.courses.map((Course course) {
                        return DropdownMenuItem<Course>(
                          value: course,
                          child: Text(course.name),
                        );
                      }).toList(),
                      onChanged: (Course? newValue) {
                        setDialogState(() => selectedCourse = newValue);
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Instructor>(
                      decoration: const InputDecoration(labelText: 'Select Instructor'),
                      value: selectedInstructor,
                      items: _scheduler.instructors.map((Instructor instructor) {
                        return DropdownMenuItem<Instructor>(
                          value: instructor,
                          child: Text(instructor.name),
                        );
                      }).toList(),
                      onChanged: (Instructor? newValue) {
                        setDialogState(() => selectedInstructor = newValue);
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 10),
                    const Text("Select Students (Optional):"),
                    if (_scheduler.students.isEmpty) const Text("No students available to enroll."),
                    ..._scheduler.students.map((student) {
                      return CheckboxListTile(
                        title: Text(student.name),
                        value: selectedStudents.any((s) => s.id == student.id), // Check if student is in selectedStudents by ID
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              if (!selectedStudents.any((s) => s.id == student.id)) {
                                selectedStudents.add(student);
                              }
                            } else {
                              selectedStudents.removeWhere((s) => s.id == student.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Add Offering'),
                  onPressed: () {
                    if (selectedCourse != null && selectedInstructor != null) {
                      String message = _scheduler.addSubjectOffering(
                        selectedCourse!.id,
                        selectedInstructor!.id,
                        selectedStudents.map((s) => s.id).toList(),
                      );
                      setState(() {}); // Refresh main page UI
                      _showSnackbar(message);
                      Navigator.of(context).pop();
                    } else {
                      _showSnackbar('Course and Instructor must be selected.', isError: true);
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }


  void _runScheduler() {
    setState(() {
      _schedulerLog = _scheduler.runScheduler();
    });
    _showSnackbar("Scheduler run complete. Check the Schedule tab for results and logs.");
  }


  // --- Builder Methods for Lists ---
  Widget _buildListView<T>(List<T> items, String title, String Function(T) itemTitle, {String emptyMessage = "No items yet."}) {
  if (items.isEmpty) {
    return Center(
      child: Padding( // Optional: Add some padding to the empty message
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(emptyMessage, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
      )
    );
  }
  return ListView.builder(
    shrinkWrap: true,                 // <<< ADD THIS LINE
    physics: const NeverScrollableScrollPhysics(), // <<< ADD THIS LINE
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text(itemTitle(item)),
          // You could add more details to the ListTile if needed:
          // subtitle: item is Student ? Text("ID: ${(item as Student).id}") : null,
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Scheduler'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Manage Data'),
            Tab(text: 'Offerings'),
            Tab(text: 'Schedule'),
            Tab(text: 'Scheduler Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Manage Data Tab ---
          _buildManageDataTab(),
          // --- Offerings Tab ---
          _buildOfferingsTab(),
          // --- Schedule Tab ---
          _buildFinalScheduleTab(),
          // --- Scheduler Log Tab ---
          _buildSchedulerLogTab(),
        ],
      ),
    );
  }

  Widget _buildManageDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Students", onPressed: () => _showAddSimpleItemDialog('Student', 'Student Name', (name) => _scheduler.addStudent(name))),
          _buildListView<Student>(_scheduler.students, "Students", (s) => "${s.id}. ${s.name}"),
          const Divider(height: 30),

          _buildSectionHeader("Instructors", onPressed: () => _showAddSimpleItemDialog('Instructor', 'Instructor Name', (name) => _scheduler.addInstructor(name))),
          _buildListView<Instructor>(_scheduler.instructors, "Instructors", (i) => "${i.id}. ${i.name}"),
          const Divider(height: 30),

          _buildSectionHeader("Courses", onPressed: () => _showAddSimpleItemDialog('Course', 'Course Name (e.g., CS101)', (name) => _scheduler.addCourse(name))),
          _buildListView<Course>(_scheduler.courses, "Courses", (c) => "${c.id}. ${c.name}"),
          const Divider(height: 30),

          _buildSectionHeader("Classrooms", onPressed: _showAddClassroomDialog),
          _buildListView<Classroom>(_scheduler.classrooms, "Classrooms", (c) => "${c.id}. ${c.name} (Cap: ${c.capacity})"),
          const Divider(height: 30),

          _buildSectionHeader("Timeslots", onPressed: () => _showAddSimpleItemDialog('Timeslot', 'Timeslot (e.g., Mon 09:00-10:00)', (ts) => _scheduler.addTimeslot(ts))),
          _buildListView<String>(_scheduler.timeslots, "Timeslots", (ts) => ts),
        ],
      ),
    );
  }

   Widget _buildOfferingsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create Subject Offering'),
            onPressed: _showAddSubjectOfferingDialog,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Offerings Queued for Scheduling", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: _buildListView<SubjectOffering>(
            _scheduler.subjectOfferingsToSchedule,
            "Offerings Queued",
            (offering) => "ID: ${offering.id} - ${offering.course.name} by ${offering.instructor.name} (${offering.studentsEnrolled.length} students)",
            emptyMessage: "No offerings queued yet."
          ),
        ),
      ],
    );
  }

  Widget _buildFinalScheduleTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.schedule_send),
            label: const Text('RUN SCHEDULER'),
            onPressed: _runScheduler,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40), backgroundColor: Colors.orangeAccent),

          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Final Generated Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: _scheduler.finalSchedule.isEmpty
              ? const Center(child: Text("No schedule generated yet, or scheduling failed.", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)))
              : ListView.builder(
                  itemCount: _scheduler.finalSchedule.length,
                  itemBuilder: (context, index) {
                    final sc = _scheduler.finalSchedule[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text("${sc.courseName} (${sc.offeringId})"),
                        subtitle: Text(
                          "Instructor: ${sc.instructorName}\nClassroom: ${sc.classroomName} @ ${sc.timeslot}\nStudents: ${sc.studentNames.join(', ')}",
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSchedulerLogTab() {
    if (_schedulerLog.isEmpty) {
      return const Center(child: Text("Run the scheduler to see logs here.", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _schedulerLog.length,
      itemBuilder: (context, index) {
        final logEntry = _schedulerLog[index];
        Color color = Colors.black;
        if (logEntry.contains("SUCCESS")) color = Colors.green.shade700;
        if (logEntry.contains("FAILURE") || logEntry.contains("Conflict") || logEntry.contains("Error")) color = Colors.red.shade700;
        if (logEntry.startsWith("---")) color = Colors.blue.shade700;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(logEntry, style: TextStyle(color: color)),
        );
      },
    );
  }


  Widget _buildSectionHeader(String title, {required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: Text('Add $title'),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}