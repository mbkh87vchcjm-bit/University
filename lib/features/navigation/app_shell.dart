import 'package:flutter/material.dart';

import '../../core/models/workspace_project.dart';
import '../../core/storage/workspace_repository.dart';
import '../common/feature_placeholder_screen.dart';
import '../home/home_screen.dart';

class AppShell extends StatefulWidget {
  final WorkspaceRepository repository;

  const AppShell({super.key, required this.repository});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _loadError;
  List<WorkspaceProject> _projects = const [];
  WorkspaceProject? _activeProject;

  @override
  void initState() {
    super.initState();
    _reloadProjects();
  }

  Future<void> _reloadProjects() async {
    try {
      final projects = await widget.repository.getProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _activeProject ??= projects.isEmpty ? null : projects.first;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'تعذّر تحميل المشاريع المحفوظة: $error';
      });
    }
  }

  Future<void> _createProject(String name) async {
    final project = await widget.repository.createProject(name);
    await _reloadProjects();
    if (!mounted) return;
    setState(() => _activeProject = project);
  }

  Future<void> _openProject(WorkspaceProject project) async {
    final opened = await widget.repository.openProject(project.id);
    await _reloadProjects();
    if (!mounted) return;
    setState(() => _activeProject = opened);
  }

  Future<void> _deleteProject(WorkspaceProject project) async {
    await widget.repository.deleteProject(project.id);
    await _reloadProjects();
    if (!mounted) return;
    if (_activeProject?.id == project.id) {
      setState(() => _activeProject = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'الرئيسية',
      ),
      NavigationDestination(
        icon: Icon(Icons.storage_outlined),
        selectedIcon: Icon(Icons.storage),
        label: 'قواعد البيانات',
      ),
      NavigationDestination(
        icon: Icon(Icons.code_outlined),
        selectedIcon: Icon(Icons.code),
        label: 'محرر SQL',
      ),
      NavigationDestination(
        icon: Icon(Icons.school_outlined),
        selectedIcon: Icon(Icons.school),
        label: 'التعلم',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_rounded),
        selectedIcon: Icon(Icons.menu_open_rounded),
        label: 'المزيد',
      ),
    ];

    final screens = [
      HomeScreen(
        projects: _projects,
        activeProject: _activeProject,
        isLoading: _isLoading,
        loadError: _loadError,
        onCreateProject: _createProject,
        onOpenProject: _openProject,
        onDeleteProject: _deleteProject,
        onRetry: _reloadProjects,
      ),
      const FeaturePlaceholderScreen(
        title: 'مستكشف قواعد البيانات',
        description: 'ستتمكن هنا من إنشاء قواعد البيانات والمخططات والجداول ومراجعة العلاقات بينها.',
        phase: 6,
        icon: Icons.storage,
      ),
      const FeaturePlaceholderScreen(
        title: 'محرر استعلامات T-SQL',
        description: 'محرر للأوامر مع التلوين والتنفيذ والنتائج ورسائل الأخطاء. سيُفعّل بعد اكتمال المحرك الأساسي.',
        phase: 7,
        icon: Icons.terminal,
      ),
      const FeaturePlaceholderScreen(
        title: 'الأكاديمية التعليمية',
        description: 'دروس عربية، أمثلة عملية، تمارين واختبارات مرتبطة بقاعدة البيانات التي تتدرب عليها.',
        phase: 15,
        icon: Icons.school,
      ),
      _MoreScreen(activeProject: _activeProject),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: destinations,
        ),
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  final WorkspaceProject? activeProject;

  const _MoreScreen({required this.activeProject});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('المزيد', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'معلومات التطبيق وإعدادات بيئة التدريب.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('ملف التوافق الدراسي المستهدف'),
            subtitle: const Text('SQL Server 2014 — Compatibility Level 120 (سيُفعّل تدريجيًا)'),
            trailing: const Icon(Icons.info_outline),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('المشروع النشط'),
            subtitle: Text(activeProject?.name ?? 'لم يتم فتح مشروع'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('وضع العمل'),
            subtitle: const Text('محلي دون الحاجة إلى حساب أو اتصال دائم بالإنترنت'),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'تنبيه: التطبيق مختبر تعليمي مستقل. لا يشغّل خدمة Microsoft SQL Server على الهاتف، وسيتم توضيح الوظائف المحاكية والوظائف غير المدعومة داخل كل درس.',
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'SQL Student Studio • إصدار تأسيسي 0.1.0',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
