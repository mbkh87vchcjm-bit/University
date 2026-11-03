import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/storage/workspace_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    SqlStudentStudioApp(
      repository: SqliteWorkspaceRepository(),
    ),
  );
}
