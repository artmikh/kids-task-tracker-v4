// lib/features/tasks/presentation/task_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../user/domain/user_profile.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';

part 'task_provider.g.dart';

@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  return TaskRepository();
}

@riverpod
Stream<List<Task>> tasksForChild(TasksForChildRef ref, String childId) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getTasksForChildStream(childId);
}

@riverpod
Stream<UserProfile?> childProfile(ChildProfileRef ref, String childId) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getChildProfileStream(childId);
}

@riverpod
class TaskController extends _$TaskController {
  @override
  TaskState build() => const TaskState();

  Future<bool> createTask(String childId, String title, String description, int stars) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(taskRepositoryProvider).createTask(childId, title, description, stars);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ИСПРАВЛЕНО: передаём taskId (String) вместо Task-объекта
  Future<bool> updateStatus(String taskId, TaskStatus newStatus) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(taskRepositoryProvider).updateTaskStatus(taskId, newStatus);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await ref.read(taskRepositoryProvider).deleteTask(id);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class TaskState {
  final bool isLoading;
  final String? error;

  const TaskState({this.isLoading = false, this.error});

  TaskState copyWith({bool? isLoading, String? error}) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}