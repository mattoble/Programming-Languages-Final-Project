// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/scheduler_provider.dart';
import 'screens/main_scheduler_screen.dart'; // Changed import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SchedulerProvider(),
      child: MaterialApp(
        title: 'Timetable Scheduler',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple, // Changed theme color for variety
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true, // Recommended for new Flutter projects
          inputDecorationTheme: InputDecorationTheme(
            // Consistent border for input fields
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        home: MainSchedulerScreen(), // Changed home screen
      ),
    );
  }
}
