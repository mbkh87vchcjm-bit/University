import 'package:flutter/material.dart';

import '../core/storage/workspace_repository.dart';
import '../features/navigation/app_shell.dart';
import 'theme.dart';

class SqlStudentStudioApp extends StatelessWidget {
  final WorkspaceRepository repository;

  const SqlStudentStudioApp({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQL Student Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: AppShell(repository: repository),
    );
  }
}
