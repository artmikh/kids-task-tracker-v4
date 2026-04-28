import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reward_repository.dart';
import '../domain/reward_model.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepository();
});

final myRewardsProvider = StreamProvider<List<Reward>>((ref) {
  final repo = ref.watch(rewardRepositoryProvider);
  return repo.getMyRewardsStream();
});

final rewardsControllerProvider = StateNotifierProvider<RewardsController, RewardsState>((ref) {
  return RewardsController(ref.watch(rewardRepositoryProvider));
});

class RewardsState {
  final bool isLoading;
  final String? error;

  RewardsState({this.isLoading = false, this.error});

  RewardsState copyWith({bool? isLoading, String? error}) {
    return RewardsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RewardsController extends StateNotifier<RewardsState> {
  final RewardRepository _repo;

  RewardsController(this._repo) : super(RewardsState());

  Future<bool> createReward({
    required String title,
    required String description,
    required RewardType type,
    int costInStars = 0,
    int durationMinutes = 0,
  }) async {
    final parentId = _repo.currentUid;
    if (parentId == null) {
      state = state.copyWith(error: 'Ошибка авторизации');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final reward = Reward(
        id: '',
        parentId: parentId,
        title: title,
        description: description,
        type: type,
        costInStars: costInStars,
        durationMinutes: durationMinutes,
        createdAt: DateTime.now(),
      );
      await _repo.addReward(reward);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateReward(Reward reward) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.updateReward(reward);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteReward(String id) async {
    try {
      await _repo.deleteReward(id);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
}