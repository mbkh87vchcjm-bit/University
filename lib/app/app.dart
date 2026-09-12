import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class SqlStudentStudioApp extends StatelessWidget {
  const SqlStudentStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQL Student Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
    );
  }
}
