import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/child_repository.dart';
import '../domain/child_model.dart';

// Провайдер репозитория
final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepository();
});

// Провайдер потока данных (список детей)
final childrenStreamProvider = StreamProvider<List<Child>>((ref) {
  final repository = ref.watch(childRepositoryProvider);
  return repository.getChildrenStream();
});

// Контроллер для действий (добавить, удалить)
final childrenControllerProvider = StateNotifierProvider<ChildrenController, ChildrenState>((ref) {
  return ChildrenController(ref.watch(childRepositoryProvider));
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
        id: '', // ID сгенерируется в Firestore
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
}