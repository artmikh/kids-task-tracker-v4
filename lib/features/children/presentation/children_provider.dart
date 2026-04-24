import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/child_repository.dart';
import '../domain/child_model.dart';
import '../../auth/presentation/auth_provider.dart'; // Импортируем провайдер авторизации

// Провайдер репозитория теперь зависит от authStateProvider.
// При смене пользователя (изменении authState) этот провайдер пересоздастся,
// что приведет к пересозданию стрима ниже.
final childRepositoryProvider = Provider<ChildRepository>((ref) {
  // Следим за состоянием авторизации. Это ключевой момент!
  final authAsync = ref.watch(authStateProvider);
  
  // Пока авторизация загружается или ошибка - возвращаем заглушку репозитория
  // (хотя стрим ниже это обработает через isEmpty)
  return ChildRepository(); 
});

// Провайдер потока данных (список детей)
final childrenStreamProvider = StreamProvider<List<Child>>((ref) {
  final repository = ref.watch(childRepositoryProvider);
  
  // Если пользователь не залогинен, возвращаем пустой список сразу
  if (repository.currentParentId == null) {
    return Stream.value([]);
  }

  // Возвращаем стрим только для текущего родителя
  return repository.getChildrenStream();
});

// Контроллер для действий (добавить, удалить)
// Также зависит от authStateProvider, чтобы иметь актуальный репозиторий
final childrenControllerProvider = StateNotifierProvider<ChildrenController, ChildrenState>((ref) {
  final repository = ref.watch(childRepositoryProvider);
  return ChildrenController(repository);
});

class ChildrenState {
  final bool isLoading;
  final String? error;

  ChildrenState({this.isLoading = false, this.error});

  ChildrenState copyWith({bool? isLoading, String? error}) {
    return ChildrenState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChildrenController extends StateNotifier<ChildrenState> {
  final ChildRepository _repository;

  ChildrenController(this._repository) : super(ChildrenState());

  Future<bool> addChild(String name, String avatarUrl) async {
    final parentId = _repository.currentParentId;
    if (parentId == null) {
      state = state.copyWith(error: 'Нет авторизованного родителя');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final newChild = Child(
        id: '', 
        parentId: parentId,
        name: name,
        avatarUrl: avatarUrl,
        stars: 0,
        createdAt: DateTime.now(),
      );
      
      await _repository.addChild(newChild);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<bool> deleteChild(String childId) async {
     state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteChild(childId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}