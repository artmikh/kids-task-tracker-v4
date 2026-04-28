import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/family_repository.dart';
import '../domain/family_invitation.dart';
import '../../user/domain/user_profile.dart';

// Провайдер репозитория
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

// --- СТРИМЫ ДАННЫХ ---

// Входящие приглашения (ожидают ответа)
final incomingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getIncomingInvitationsStream();
});

// Исходящие приглашения (отправлены нами, ждем ответа)
final outgoingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getOutgoingInvitationsStream();
});

// Список детей (для родителя)
final myChildrenProvider = StreamProvider<List<UserProfile>>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getMyChildrenStream();
});

// Список родителей (для ребенка)
final myParentsProvider = StreamProvider<List<UserProfile>>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getMyParentsStream();
});

// --- КОНТРОЛЛЕР ДЕЙСТВИЙ ---

final familyControllerProvider = StateNotifierProvider<FamilyController, FamilyState>((ref) {
  return FamilyController(ref.watch(familyRepositoryProvider));
});

class FamilyState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  FamilyState({this.isLoading = false, this.error, this.successMessage});

  FamilyState copyWith({bool? isLoading, String? error, String? successMessage}) {
    return FamilyState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class FamilyController extends StateNotifier<FamilyState> {
  final FamilyRepository _repository;

  FamilyController(this._repository) : super(FamilyState());

  /// Отправить приглашение
  Future<bool> sendInvitation(String email, InvitationType type) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _repository.sendInvitation(email, type);
      state = state.copyWith(
        isLoading: false, 
        successMessage: 'Приглашение отправлено на $email',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Принять приглашение
  Future<bool> acceptInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.acceptInvitation(invitationId);
      state = state.copyWith(
        isLoading: false, 
        successMessage: 'Приглашение принято!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Отклонить приглашение
  Future<bool> rejectInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.rejectInvitation(invitationId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}