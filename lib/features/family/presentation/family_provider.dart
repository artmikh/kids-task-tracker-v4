import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/family_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_provider.dart'; // Для доступа к authRepositoryProvider если нужно

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

// Поток входящих приглашений
final incomingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getIncomingInvitationsStream();
});

// Поток связей (дети для родителя)
final myChildrenLinksProvider = StreamProvider<List<FamilyLink>>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getMyChildrenLinksStream();
});

// Контроллер для действий
final familyControllerProvider = StateNotifierProvider<FamilyController, FamilyState>((ref) {
  return FamilyController(ref.watch(familyRepositoryProvider));
});

class FamilyState {
  final bool isLoading;
  final String? error;
  FamilyState({this.isLoading = false, this.error});
  FamilyState copyWith({bool? isLoading, String? error}) => 
    FamilyState(isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class FamilyController extends StateNotifier<FamilyState> {
  final FamilyRepository _repo;
  FamilyController(this._repo) : super(FamilyState());

  Future<bool> sendInvite(String email, String type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.sendInvitation(toEmail: email, type: type);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> acceptInvite(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.acceptInvitation(id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  Future<bool> rejectInvite(String id) async {
     try {
      await _repo.rejectInvitation(id);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}