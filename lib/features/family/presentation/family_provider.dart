// lib/features/family/presentation/family_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/family_repository.dart';
import '../domain/family_invitation.dart';
import '../../user/domain/user_profile.dart';

part 'family_provider.g.dart';

@riverpod
FamilyRepository familyRepository(FamilyRepositoryRef ref) {
  return FamilyRepository();
}

@riverpod
Stream<List<FamilyInvitation>> incomingInvitations(IncomingInvitationsRef ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getIncomingInvitationsStream();
}

@riverpod
Stream<List<FamilyInvitation>> outgoingInvitations(OutgoingInvitationsRef ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getOutgoingInvitationsStream();
}

@riverpod
Stream<List<UserProfile>> myChildren(MyChildrenRef ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getMyChildrenStream();
}

@riverpod
Stream<List<UserProfile>> myParents(MyParentsRef ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getMyParentsStream();
}

@riverpod
class FamilyController extends _$FamilyController {
  @override
  FamilyState build() => const FamilyState();

  Future<bool> sendInvitation(String email, InvitationType type) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await ref.read(familyRepositoryProvider).sendInvitation(email, type);
      state = state.copyWith(isLoading: false, successMessage: 'Приглашение отправлено на $email');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> acceptInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(familyRepositoryProvider).acceptInvitation(invitationId);
      state = state.copyWith(isLoading: false, successMessage: 'Приглашение принято!');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> rejectInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(familyRepositoryProvider).rejectInvitation(invitationId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

class FamilyState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const FamilyState({this.isLoading = false, this.error, this.successMessage});

  FamilyState copyWith({bool? isLoading, String? error, String? successMessage}) {
    return FamilyState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}