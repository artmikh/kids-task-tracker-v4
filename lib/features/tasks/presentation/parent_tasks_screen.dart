import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/task_model.dart';
import '../../auth/presentation/auth_provider.dart';
import 'task_provider.dart';

class ParentTasksScreen extends ConsumerStatefulWidget {
  final String childId;
  final String childName;

  const ParentTasksScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  ConsumerState<ParentTasksScreen> createState() => _ParentTasksScreenState();
}

class _ParentTasksScreenState extends ConsumerState<ParentTasksScreen> {
  TaskStatus? selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskControllerProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(taskControllerProvider);
    final tasksAsync = ref.watch(tasksForChildProvider(widget.childId));

    // Обработка ошибок
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          ref.read(taskControllerProvider.notifier).clearError();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Задачи: ${widget.childName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Блок фильтров ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Все'),
                    selected: selectedFilter == null,
                    onSelected: (_) => setState(() => selectedFilter = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Ожидание'),
                    selected: selectedFilter == TaskStatus.todo,
                    onSelected: (_) =>
                        setState(() => selectedFilter = TaskStatus.todo),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('В процессе'),
                    selected: selectedFilter == TaskStatus.inProgress,
                    onSelected: (_) =>
                        setState(() => selectedFilter = TaskStatus.inProgress),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('На проверке'),
                    selected: selectedFilter == TaskStatus.review,
                    onSelected: (_) =>
                        setState(() => selectedFilter = TaskStatus.review),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Готово'),
                    selected: selectedFilter == TaskStatus.done,
                    onSelected: (_) =>
                        setState(() => selectedFilter = TaskStatus.done),
                  ),
                ],
              ),
            ),
          ),

          // --- Список задач ---
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                // Сортируем: review первые (надо проверить!), потом inProgress, todo, done
                final priorityOrder = {
                  TaskStatus.review: 0,
                  TaskStatus.inProgress: 1,
                  TaskStatus.todo: 2,
                  TaskStatus.done: 3,
                };

                final sortedTasks = List<Task>.from(tasks)
                  ..sort((a, b) => priorityOrder[a.status]!
                      .compareTo(priorityOrder[b.status]!));

                final filteredTasks = selectedFilter == null
                    ? sortedTasks
                    : sortedTasks
                        .where((t) => t.status == selectedFilter)
                        .toList();

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text(
                          selectedFilter == null
                              ? 'Задач пока нет'
                              : 'Нет задач в этом статусе',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (ctx, i) {
                    final task = filteredTasks[i];
                    return _ParentTaskCard(
                      task: task,
                      onApprove: () => _approveTask(task),
                      onReject: () => _rejectTask(task),
                      onEdit: () => _showTaskDialog(context, ref, task: task),
                      onDelete: () => _confirmDelete(context, task.id),
                      onStatusChange: (status) => ref
                          .read(taskControllerProvider.notifier)
                          .updateStatus(
                            task.id,
                            status,
                            currentRevisionCount: task.revisionCount,
                          ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Ошибка: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _approveTask(Task task) {
    ref.read(taskControllerProvider.notifier).updateStatus(
      task.id,
      TaskStatus.done,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ «${task.title}» подтверждено! +${task.rewardStars} ⭐'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectTask(Task task) {
    // Возвращаем на inProgress — это увеличит revisionCount
    ref.read(taskControllerProvider.notifier).updateStatus(
      task.id,
      TaskStatus.inProgress,
      currentRevisionCount: task.revisionCount,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('↩️ «${task.title}» возвращено на доработку'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить задачу?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(taskControllerProvider.notifier).deleteTask(id);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog(BuildContext context, WidgetRef ref, {Task? task}) {
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');
    final starsCtrl =
        TextEditingController(text: task?.rewardStars.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? 'Новая задача' : 'Редактировать задачу'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Название *', border: OutlineInputBorder()),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Описание', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: starsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Награда (звезды) *',
                      prefixIcon: Icon(Icons.star),
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                if (task != null) ...[
                  const SizedBox(height: 16),
                  Text('Текущий статус: ${task.statusLabel}',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    starsCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Заполните название и награду')));
                  return;
                }
                final rewardStars =
                    int.tryParse(starsCtrl.text.trim()) ?? 0;
                if (rewardStars <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Награда должна быть больше 0')));
                  return;
                }

                if (task == null) {
                  await ref
                      .read(taskControllerProvider.notifier)
                      .createTask(
                        widget.childId,
                        titleCtrl.text.trim(),
                        descCtrl.text.trim(),
                        rewardStars,
                      );
                } else {
                  final updatedTask = task.copyWith(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    rewardStars: rewardStars,
                  );
                  await ref
                      .read(taskRepositoryProvider)
                      .updateTask(updatedTask);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Карточка задачи для родителя ---

class _ParentTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(TaskStatus) onStatusChange;

  const _ParentTaskCard({
    required this.task,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReview = task.status == TaskStatus.review;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isReview
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      elevation: isReview ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок + статус
            Row(
              children: [
                _getStatusIcon(task.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration: task.status == TaskStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                // Награда
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('${task.rewardStars}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            // Описание
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Статус + доработка
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.statusLabel,
                    style: TextStyle(
                      color: _getStatusColor(task.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (task.isRevision) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Доработка ×${task.revisionCount}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Кнопки проверки (только для задач на проверке)
            if (isReview) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('На доработку'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Подтвердить'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Меню действий (для всех задач)
            if (!isReview) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Редактировать'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return const CircleAvatar(
            radius: 16,
            child: Icon(Icons.radio_button_unchecked, size: 18));
      case TaskStatus.inProgress:
        return const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Icon(Icons.play_arrow, color: Colors.white, size: 18));
      case TaskStatus.review:
        return const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.orange,
            child: Icon(Icons.visibility, color: Colors.white, size: 18));
      case TaskStatus.done:
        return const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green,
            child: Icon(Icons.check, color: Colors.white, size: 18));
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.review:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
    }
  }
}