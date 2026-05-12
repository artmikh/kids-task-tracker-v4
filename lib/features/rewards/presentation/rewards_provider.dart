// lib/features/rewards/presentation/rewards_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/reward_repository.dart';
import '../domain/reward_model.dart';

part 'rewards_provider.g.dart';

@riverpod
RewardRepository rewardRepository(RewardRepositoryRef ref) {
  return RewardRepository();
}

@riverpod
Stream<List<Reward>> myRewards(MyRewardsRef ref) {
  final repo = ref.watch(rewardRepositoryProvider);
  return repo.getMyRewardsStream();
}

@riverpod
class RewardsController extends _$RewardsController {
  @override
  RewardsState build() => const RewardsState();

  Future<bool> createReward({
    required String title,
    required String description,
    required RewardType type,
    int costInStars = 0,
    int durationMinutes = 0,
  }) async {
    final parentId = ref.read(rewardRepositoryProvider).currentUid;
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
      await ref.read(rewardRepositoryProvider).addReward(reward);
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
      await ref.read(rewardRepositoryProvider).updateReward(reward);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteReward(String id) async {
    try {
      await ref.read(rewardRepositoryProvider).deleteReward(id);
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

class RewardsState {
  final bool isLoading;
  final String? error;

  const RewardsState({this.isLoading = false, this.error});

  RewardsState copyWith({bool? isLoading, String? error}) {
    return RewardsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}