import 'package:flutter/material.dart';

import '../../core/models/workspace_project.dart';

class HomeScreen extends StatelessWidget {
  final List<WorkspaceProject> projects;
  final WorkspaceProject? activeProject;
  final bool isLoading;
  final String? loadError;
  final Future<void> Function(String name) onCreateProject;
  final Future<void> Function(WorkspaceProject project) onOpenProject;
  final Future<void> Function(WorkspaceProject project) onDeleteProject;
  final VoidCallback onRetry;

  const HomeScreen({
    super.key,
    required this.projects,
    required this.activeProject,
    required this.isLoading,
    required this.loadError,
    required this.onCreateProject,
    required this.onOpenProject,
    required this.onDeleteProject,
    required this.onRetry,
  });

  Future<void> _createProject(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateProjectDialog(),
    );

    if (name == null || !context.mounted) return;
    try {
      await onCreateProject(name);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء المشروع وحفظه على الجهاز.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إنشاء المشروع: $error')),
      );
    }
  }

  Future<void> _deleteProject(
    BuildContext context,
    WorkspaceProject project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المشروع؟'),
        content: Text(
          'سيتم حذف سجل مساحة العمل «${project.name}». لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await onDeleteProject(project);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المشروع.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر حذف المشروع: $error')),
      );
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('SQL Student Studio'),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'إنشاء مشروع',
              onPressed: () => _createProject(context),
              icon: const Icon(Icons.create_new_folder_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('مختبر قواعد البيانات', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'مساحة تدريب محلية لتعلّم SQL Server وكتابة أوامر T-SQL خطوة بخطوة.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _ActiveProjectCard(
                project: activeProject,
                dateFormatter: _formatDate,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'مشاريعي',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${projects.length} مشروع',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (loadError != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loadError!),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (projects.isEmpty)
                _EmptyProjectsCard(onCreate: () => _createProject(context))
              else
                ...projects.map(
                  (project) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ProjectTile(
                      project: project,
                      isActive: activeProject?.id == project.id,
                      date: _formatDate(project.createdAt),
                      onOpen: () async {
                        try {
                          await onOpenProject(project);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم فتح «${project.name}».')),
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذّر فتح المشروع: $error')),
                          );
                        }
                      },
                      onDelete: () => _deleteProject(context, project),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'التطبيق في مرحلته التأسيسية. إنشاء المشاريع وحفظها يعملان محليًا؛ تنفيذ استعلامات SQL ومستكشف قواعد البيانات سيُفعّلان بعد اكتمال محرك البيانات.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ActiveProjectCard extends StatelessWidget {
  final WorkspaceProject? project;
  final String Function(DateTime) dateFormatter;

  const _ActiveProjectCard({
    required this.project,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.primaryContainer, colors.surfaceContainerHighest],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special_outlined, color: colors.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'مساحة العمل الحالية',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              project?.name ?? 'لم تفتح مشروعًا بعد',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project == null
                  ? 'أنشئ مشروعًا لحفظ عملك وتنظيم تدريباتك.'
                  : 'آخر فتح: ${dateFormatter(project!.lastOpenedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjectsCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyProjectsCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: Column(
          children: [
            Icon(Icons.create_new_folder_outlined, size: 42, color: colors.primary),
            const SizedBox(height: 12),
            Text('لا توجد مشاريع محفوظة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'أنشئ مشروعك الأول. ستُحفظ بيانات مساحة العمل على هذا الجهاز.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء أول مشروع'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final WorkspaceProject project;
  final bool isActive;
  final String date;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ProjectTile({
    required this.project,
    required this.isActive,
    required this.date,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          child: Icon(isActive ? Icons.folder_special : Icons.folder_outlined),
        ),
        title: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('أُنشئ في $date'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'فتح المشروع',
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
            ),
            PopupMenuButton<String>(
              tooltip: 'إجراءات المشروع',
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('حذف المشروع'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog();

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إنشاء مشروع جديد'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 60,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'اسم المشروع',
            hintText: 'مثال: قاعدة بيانات الجامعة',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'اكتب اسمًا للمشروع.';
            if (text.length > 60) return 'الاسم يجب ألا يتجاوز 60 حرفًا.';
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('إنشاء'),
        ),
      ],
    );
  }
}
