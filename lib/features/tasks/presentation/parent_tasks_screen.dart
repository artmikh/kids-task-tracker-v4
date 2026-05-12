import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/task_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../family/presentation/family_provider.dart';
import '../../user/domain/user_profile.dart';
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
                final filteredTasks = selectedFilter == null
                    ? tasks
                    : tasks.where((t) => t.status == selectedFilter).toList();

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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _getStatusIcon(task.status),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.status == TaskStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description.isNotEmpty)
                              Text(task.description,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${task.rewardStars} звезд',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                                const Spacer(),
                                Text(_getStatusText(task.status),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            _getStatusColor(task.status))),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showTaskDialog(context, ref, task: task);
                            }
                            if (val == 'delete') {
                              _confirmDelete(context, task.id);
                            }
                            if (val == 'todo') {
                              ref
                                  .read(taskControllerProvider.notifier)
                                  .updateStatus(task.id, TaskStatus.todo);
                            }
                            if (val == 'in_progress') {
                              ref
                                  .read(taskControllerProvider.notifier)
                                  .updateStatus(
                                      task.id, TaskStatus.inProgress);
                            }
                            if (val == 'done') {
                              ref
                                  .read(taskControllerProvider.notifier)
                                  .updateStatus(task.id, TaskStatus.done);
                              ref.invalidate(myChildrenProvider);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'todo',
                                child: Text('Вернуть в ожидание')),
                            const PopupMenuItem(
                                value: 'in_progress',
                                child: Text('В процессе')),
                            const PopupMenuItem(
                                value: 'done', child: Text('Завершено')),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                                value: 'edit',
                                child: Text('Редактировать')),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text('Удалить',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
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

  Widget _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return const CircleAvatar(
            child: Icon(Icons.radio_button_unchecked));
      case TaskStatus.inProgress:
        return const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.play_arrow, color: Colors.white));
      case TaskStatus.done:
        return const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.check, color: Colors.white));
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'Ожидает';
      case TaskStatus.inProgress:
        return 'В процессе';
      case TaskStatus.done:
        return 'Готово';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
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
                  Text('Текущий статус: ${_getStatusText(task.status)}',
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
                  // Создание новой задачи
                  await ref
                      .read(taskControllerProvider.notifier)
                      .createTask(
                        widget.childId,
                        titleCtrl.text.trim(),
                        descCtrl.text.trim(),
                        rewardStars,
                      );
                } else {
                  // Редактирование — обновляем текст и награду
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