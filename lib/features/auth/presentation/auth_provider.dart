// lib/features/auth/presentation/auth_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';
import '../../user/domain/user_profile.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository();
}

@riverpod
Stream<UserProfile?> authState(AuthStateRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
}

@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() => const AuthState();

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).createUserWithEmailAndPassword(email, password, name, role);
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

class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}