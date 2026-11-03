import 'package:flutter/material.dart';

import '../core/storage/workspace_repository.dart';
import '../core/logging/app_logger.dart';
import '../features/navigation/app_shell.dart';
import 'theme.dart';

class SqlStudentStudioApp extends StatefulWidget {
  final WorkspaceRepository repository;

  const SqlStudentStudioApp({super.key, required this.repository});

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
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Could not load the saved theme preference; using system theme.',
        error: error,
      );
      AppLogger.error(
        'Theme preference loading failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    try {
      await widget.repository.setThemeMode(mode.name);
      if (!mounted) return;
      setState(() => _themeMode = mode);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Could not save the theme preference.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذّر حفظ إعداد المظهر.')));
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
