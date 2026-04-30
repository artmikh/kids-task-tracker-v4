import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../user/domain/user_profile.dart';

// Провайдеры
final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository());

final tasksStreamProvider = StreamProvider.family<List<Task>, String>((ref, childId) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getTasksForChildStream(childId);
});

final taskControllerProvider = StateNotifierProvider.family<TaskController, TaskState, String>((ref, childId) {
  return TaskController(ref.watch(taskRepositoryProvider), childId);
});

class TaskState {
  final bool isLoading;
  final String? error;
  TaskState({this.isLoading = false, this.error});
  TaskState copyWith({bool? isLoading, String? error}) => 
    TaskState(isLoading: isLoading ?? this.isLoading, error: error);
}

class TaskController extends StateNotifier<TaskState> {
  final TaskRepository _repo;
  final String _childId;

  TaskController(this._repo, this._childId) : super(TaskState());

  Future<bool> addTask(String title, String description, int stars) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.createTask(_childId, title, description, stars);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try { await _repo.deleteTask(taskId); } 
    catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    try { 
      await _repo.updateTaskStatus(taskId, status); 
    }
    catch (e) { state = state.copyWith(error: e.toString()); }
  }
  
  void clearError() => state = state.copyWith(error: null);
}

// Экран
class ParentTasksScreen extends ConsumerStatefulWidget {
  final String childId;
  final String childName;

  const ParentTasksScreen({super.key, required this.childId, required this.childName});

  @override
  ConsumerState<ParentTasksScreen> createState() => _ParentTasksScreenState();
}

class _ParentTasksScreenState extends ConsumerState<ParentTasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskControllerProvider(widget.childId).notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(taskControllerProvider(widget.childId));
    final tasksAsync = ref.watch(tasksStreamProvider(widget.childId));

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: Colors.red));
          ref.read(taskControllerProvider(widget.childId).notifier).clearError();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Задачи: ${widget.childName}'),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.list_alt, size: 64, color: theme.disabledColor),
                const SizedBox(height: 16),
                Text('Задач пока нет', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('Создайте первую задачу для мотивации!', style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
              ]),
            );
          }
          
          // Группировка по статусам для наглядности (опционально, пока просто список)
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (ctx, i) {
              final task = tasks[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _getStatusIcon(task.status),
                  title: Text(task.title, style: TextStyle(decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (task.description.isNotEmpty) Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${task.rewardStars} звезд', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      Text(_getStatusText(task.status), style: TextStyle(fontSize: 12, color: _getStatusColor(task.status))),
                    ]),
                  ]),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') { /* TODO: Редактирование */ }
                      if (val == 'delete') _confirmDelete(context, task.id);
                      if (val == 'todo') ref.read(taskControllerProvider(widget.childId).notifier).updateStatus(task.id, TaskStatus.todo);
                      if (val == 'in_progress') ref.read(taskControllerProvider(widget.childId).notifier).updateStatus(task.id, TaskStatus.inProgress);
                      if (val == 'done') ref.read(taskControllerProvider(widget.childId).notifier).updateStatus(task.id, TaskStatus.done);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'todo', child: Text('Вернуть в ожидание')),
                      const PopupMenuItem(value: 'in_progress', child: Text('В процессе')),
                      const PopupMenuItem(value: 'done', child: Text('Завершено')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                      const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo: return const CircleAvatar(child: Icon(Icons.radio_button_unchecked));
      case TaskStatus.inProgress: return const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.play_arrow, color: Colors.white));
      case TaskStatus.done: return const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white));
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo: return 'Ожидает';
      case TaskStatus.inProgress: return 'В процессе';
      case TaskStatus.done: return 'Готово';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo: return Colors.grey;
      case TaskStatus.inProgress: return Colors.blue;
      case TaskStatus.done: return Colors.green;
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Удалить задачу?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), 
          onPressed: () { ref.read(taskControllerProvider(widget.childId).notifier).deleteTask(id); Navigator.pop(ctx); },
          child: const Text('Удалить')),
      ],
    ));
  }

  void _showTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final starsCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Новая задача'),
      content: SingleChildScrollView(
        child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название *'), validator: (v) => v!.isEmpty ? 'Обязательно' : null),
          const SizedBox(height: 16),
          TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Описание'), maxLines: 2),
          const SizedBox(height: 16),
          TextFormField(controller: starsCtrl, decoration: const InputDecoration(labelText: 'Награда (звезды) *', prefixIcon: Icon(Icons.star)), 
            keyboardType: TextInputType.number, validator: (v) {
              if (v!.isEmpty) return 'Обязательно';
              if (int.tryParse(v) == null) return 'Только числа';
              return null;
            }),
        ])),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          final stars = int.parse(starsCtrl.text);
          final success = await ref.read(taskControllerProvider(widget.childId).notifier).addTask(titleCtrl.text, descCtrl.text, stars);
          if (success && ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Создать')),
      ],
    ));
  }
}