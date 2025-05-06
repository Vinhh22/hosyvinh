import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:taskmanager/taskManager/view/LoginScreen.dart';
import 'package:taskmanager/taskManager/view/RegisterScreen.dart';
import 'package:taskmanager/taskManager/view/TaskDetailScreen.dart';
import 'package:taskmanager/taskManager/view/TaskListScreen.dart';
import 'package:taskmanager/taskManager/view/TaskFormScreen.dart';
import 'package:taskmanager/taskManager/model/TaskModel.dart';
import 'package:taskmanager/taskManager/model/UserModel.dart';
import 'dart:developer' as developer;
void main() async {

  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  ThemeData get _lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[900],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.blue[300],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/task_list':
            final user = settings.arguments as User;
            return MaterialPageRoute(
              builder: (_) => TaskListScreen(
                currentUser: user,
              ),
            );
          case '/task_detail':
          // Đảm bảo arguments là một Map chứa cả task và currentUser
            final args = settings.arguments as Map<String, dynamic>;
            final task = args['task'] as Task;
            final currentUser = args['currentUser'] as User;
            return MaterialPageRoute(
              builder: (_) => TaskDetailScreen(
                task: task,
                currentUser: currentUser,
              ),
            );
          case '/task_form':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => TaskFormScreen(
                currentUser: args['currentUser'],
                task: args['task'],
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
      builder: (context, child) {
        return ThemeSwitchingWidget(
          toggleTheme: _toggleTheme,
          isDarkMode: _isDarkMode,
          child: child!,
        );
      },
    );
  }
}

class ThemeSwitchingWidget extends InheritedWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const ThemeSwitchingWidget({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required super.child,
  });

  static ThemeSwitchingWidget of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeSwitchingWidget>()!;
  }

  @override
  bool updateShouldNotify(ThemeSwitchingWidget oldWidget) {
    return oldWidget.isDarkMode != isDarkMode;
  }
}