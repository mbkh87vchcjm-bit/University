import 'dart:developer' as developer;

class AppLogger {
  AppLogger._();

  static const _scope = 'sql_student_studio';

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _scope,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message, {Object? error}) {
    developer.log(message, name: _scope, level: 900, error: error);
  }
}
