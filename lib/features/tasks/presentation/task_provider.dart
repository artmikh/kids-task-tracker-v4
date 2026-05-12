import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/domain/user_profile.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// Поток задач для выбранного ребенка
final tasksForChildProvider = StreamProvider.family<List<Task>, String>((ref, childId) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getTasksForChildStream(childId);
});

// Поток профиля ребенка (чтобы видеть баланс звезд)
final childProfileProvider = StreamProvider.family<UserProfile?, String>((ref, childId) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getChildProfileStream(childId);
});

// Контроллер действий
final taskControllerProvider = StateNotifierProvider<TaskController, TaskState>((ref) {
  return TaskController(ref.watch(taskRepositoryProvider));
});

class TaskState {
  final bool isLoading;
  final String? error;

  TaskState({this.isLoading = false, this.error});

  TaskState copyWith({bool? isLoading, String? error}) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TaskController extends StateNotifier<TaskState> {
  final TaskRepository _repo;

  TaskController(this._repo) : super(TaskState());

  Future<bool> createTask(String childId, String title, String description, int stars) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.createTask(childId, title, description, stars);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateStatus(Task task, TaskStatus newStatus) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.updateTaskStatus(task, newStatus);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repo.deleteTask(id);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
}