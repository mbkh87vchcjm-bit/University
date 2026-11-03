import 'package:flutter/material.dart';

import '../core/storage/workspace_repository.dart';
import '../features/navigation/app_shell.dart';
import 'theme.dart';

class SqlStudentStudioApp extends StatefulWidget {
  final WorkspaceRepository repository;

  const SqlStudentStudioApp({
    super.key,
    required this.repository,
  });

  @override
  State<SqlStudentStudioApp> createState() => _SqlStudentStudioAppState();
}

class _SqlStudentStudioAppState extends State<SqlStudentStudioApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final storedMode = await widget.repository.getThemeMode();
      if (!mounted) return;
      setState(() {
        _themeMode = switch (storedMode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      });
    } catch (_) {
      // Keep the system theme when settings cannot be read.
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    try {
      await widget.repository.setThemeMode(mode.name);
      if (!mounted) return;
      setState(() => _themeMode = mode);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ إعداد المظهر.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQL Student Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AppShell(
        repository: widget.repository,
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
