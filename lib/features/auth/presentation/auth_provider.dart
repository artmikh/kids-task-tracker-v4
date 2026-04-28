import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
// Импортируем новую модель профиля вместо старой AppUser
import '../../user/domain/user_profile.dart'; 

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Теперь стрим возвращает UserProfile?
final authStateProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthState {
  final bool isLoading;
  final String? error;

  AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.signInWithEmailAndPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // Обновленный метод регистрации: добавлен параметр role
  Future<bool> signUp(String email, String password, String name, UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Передаем роль в репозиторий
      await _repository.createUserWithEmailAndPassword(email, password, name, role);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}