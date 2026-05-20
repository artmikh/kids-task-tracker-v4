import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../user/domain/user_profile.dart';
import 'task_provider.dart';

class ChildTasksScreen extends ConsumerWidget {
  const ChildTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _ChildTasksContent(user: user);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Ошибка: $err'))),
    );
  }
}

class _ChildTasksContent extends ConsumerStatefulWidget {
  final UserProfile user;

  const _ChildTasksContent({required this.user});

  @override
  ConsumerState<_ChildTasksContent> createState() => _ChildTasksContentState();
}

class _ChildTasksContentState extends ConsumerState<_ChildTasksContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksForChildProvider(widget.user.uid));
    final profileAsync = ref.watch(childProfileProvider(widget.user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои задачи'),
        actions: [
          // Баланс звёзд
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: profileAsync.when(
                data: (profile) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      '${profile?.stars ?? 0}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Icon(Icons.error_outline, size: 20),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 80, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'Задач пока нет',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Родитель ещё не добавил задания',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          // Разделяем задачи по статусам
          final todoTasks = tasks.where((t) => t.status == TaskStatus.todo).toList();
          final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
          final reviewTasks = tasks.where((t) => t.status == TaskStatus.review).toList();
          final doneTasks = tasks.where((t) => t.status == TaskStatus.done).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tasksForChildProvider(widget.user.uid));
              ref.invalidate(childProfileProvider(widget.user.uid));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (inProgressTasks.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.play_arrow,
                    title: 'В процессе',
                    color: Colors.blue,
                    count: inProgressTasks.length,
                  ),
                  const SizedBox(height: 8),
                  ...inProgressTasks.map((task) => _TaskCard(
                        task: task,
                        isChild: true,
                        onStatusChange: (newStatus) => _changeStatus(task, newStatus),
                      )),
                  const SizedBox(height: 16),
                ],
                if (todoTasks.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.radio_button_unchecked,
                    title: 'Нужно сделать',
                    color: Colors.grey,
                    count: todoTasks.length,
                  ),
                  const SizedBox(height: 8),
                  ...todoTasks.map((task) => _TaskCard(
                        task: task,
                        isChild: true,
                        onStatusChange: (newStatus) => _changeStatus(task, newStatus),
                      )),
                  const SizedBox(height: 16),
                ],
                if (reviewTasks.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.visibility,
                    title: 'На проверке',
                    color: Colors.orange,
                    count: reviewTasks.length,
                  ),
                  const SizedBox(height: 8),
                  ...reviewTasks.map((task) => _TaskCard(
                        task: task,
                        isChild: true,
                        onStatusChange: (newStatus) => _changeStatus(task, newStatus),
                      )),
                  const SizedBox(height: 16),
                ],
                if (doneTasks.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.check_circle,
                    title: 'Готово!',
                    color: Colors.green,
                    count: doneTasks.length,
                  ),
                  const SizedBox(height: 8),
                  ...doneTasks.map((task) => _TaskCard(
                        task: task,
                        isChild: true,
                        onStatusChange: (newStatus) => _changeStatus(task, newStatus),
                      )),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  void _changeStatus(Task task, TaskStatus newStatus) {
    // Ребёнок НЕ передаёт currentRevisionCount — 
    // инкремент происходит только когда родитель возвращает на доработку
    ref.read(taskControllerProvider.notifier).updateStatus(task.id, newStatus);
  }
}

// --- Виджеты-помощники ---

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool isChild;
  final void Function(TaskStatus) onStatusChange;

  const _TaskCard({
    required this.task,
    required this.isChild,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _getBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Бейдж "Доработка" если задача возвращалась
            if (task.isRevision && task.status != TaskStatus.done) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Доработка${task.revisionCount > 1 ? " ×${task.revisionCount}" : ""}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Заголовок + награда
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration: task.status == TaskStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.status == TaskStatus.done
                          ? theme.disabledColor
                          : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${task.rewardStars}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
            // Кнопки действий (для ребёнка)
            if (isChild && task.status != TaskStatus.done && task.status != TaskStatus.review) ...[
              const SizedBox(height: 12),
              Row(
                children: _buildActionButtons(context),
              ),
            ],
            // Инфо для задач на проверке
            if (isChild && task.status == TaskStatus.review) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ждём проверки у родителя',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BorderSide _getBorderSide() {
    switch (task.status) {
      case TaskStatus.review:
        return BorderSide(color: Colors.orange.withOpacity(0.4));
      case TaskStatus.done:
        return BorderSide(color: Colors.green.withOpacity(0.3));
      default:
        return BorderSide.none;
    }
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    switch (task.status) {
      case TaskStatus.todo:
        return [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => onStatusChange(TaskStatus.inProgress),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Начать'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(36),
              ),
            ),
          ),
        ];
      case TaskStatus.inProgress:
        return [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onStatusChange(TaskStatus.todo),
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Назад'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => onStatusChange(TaskStatus.review),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('На проверку'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(36),
              ),
            ),
          ),
        ];
      case TaskStatus.review:
        return []; // Ребёнок не может менять статус — ждёт родителя
      case TaskStatus.done:
        return []; // Завершено
    }
  }
}