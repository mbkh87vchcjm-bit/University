import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/app/app.dart';
import 'package:sql_student_studio/core/models/workspace_project.dart';
import 'package:sql_student_studio/core/storage/workspace_repository.dart';

class _MemoryWorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceProject> _projects = [];
  int _nextId = 1;

  @override
  Future<List<WorkspaceProject>> getProjects() async =>
      List.unmodifiable(_projects);

  @override
  Future<WorkspaceProject> createProject(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Project name cannot be empty.');
    }
    final now = DateTime.now().toUtc();
    final project = WorkspaceProject(
      id: _nextId++,
      name: normalized,
      createdAt: now,
      lastOpenedAt: now,
    );
    _projects.add(project);
    return project;
  }

  @override
  Future<WorkspaceProject> openProject(int id) async {
    final index = _projects.indexWhere((project) => project.id == id);
    if (index < 0) throw StateError('Project not found.');
    final old = _projects[index];
    final opened = WorkspaceProject(
      id: old.id,
      name: old.name,
      createdAt: old.createdAt,
      lastOpenedAt: DateTime.now().toUtc(),
    );
    _projects[index] = opened;
    return opened;
  }

  @override
  Future<void> deleteProject(int id) async {
    _projects.removeWhere((project) => project.id == id);
  }

  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('app displays the SQL Student Studio home and navigation',
      (tester) async {
    await tester.pumpWidget(
      SqlStudentStudioApp(repository: _MemoryWorkspaceRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('SQL Student Studio'), findsOneWidget);
    expect(find.text('مختبر قواعد البيانات'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('محرر SQL'), findsOneWidget);
  });

  testWidgets('student can create a local workspace project', (tester) async {
    await tester.pumpWidget(
      SqlStudentStudioApp(repository: _MemoryWorkspaceRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('إنشاء أول مشروع'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'قاعدة بيانات الجامعة',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'إنشاء'));
    await tester.pumpAndSettle();

    expect(find.text('قاعدة بيانات الجامعة'), findsWidgets);
    expect(find.text('تم إنشاء المشروع وحفظه على الجهاز.'), findsOneWidget);
  });

  testWidgets('database and query screens clearly show their planned status',
      (tester) async {
    await tester.pumpWidget(
      SqlStudentStudioApp(repository: _MemoryWorkspaceRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('قواعد البيانات'));
    await tester.pumpAndSettle();
    expect(find.text('مستكشف قواعد البيانات'), findsOneWidget);
    expect(find.text('مخطط تنفيذها في المرحلة 6'), findsOneWidget);

    await tester.tap(find.text('محرر SQL'));
    await tester.pumpAndSettle();
    expect(find.text('محرر استعلامات T-SQL'), findsOneWidget);
    expect(find.text('مخطط تنفيذها في المرحلة 7'), findsOneWidget);
  });

  testWidgets('student can open and delete a project with confirmation',
      (tester) async {
    final repository = _MemoryWorkspaceRepository();
    await repository.createProject('مشروع الاختبار');

    await tester.pumpWidget(SqlStudentStudioApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('فتح المشروع'));
    await tester.pumpAndSettle();
    expect(find.text('مشروع الاختبار'), findsWidgets);

    await tester.tap(find.byTooltip('إجراءات المشروع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف المشروع'));
    await tester.pumpAndSettle();

    expect(find.text('حذف المشروع؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد مشاريع محفوظة'), findsOneWidget);
  });
}
