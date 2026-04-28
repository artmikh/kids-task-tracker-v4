import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/reward_repository.dart';
import '../domain/reward_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../user/domain/user_profile.dart'; // Добавлен импорт

// --- PROVIDERS ---

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepository();
});

// final myRewardsProvider = StreamProvider<List<Reward>>((ref) {
//   final repo = ref.watch(rewardRepositoryProvider);
//   return repo.getMyRewardsStream();
// });

final myRewardsProvider = StreamProvider<List<Reward>>((ref) {
  // Следим за состоянием авторизации. При смене пользователя этот блок выполнится заново
  final userAsync = ref.watch(authStateProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final repo = ref.watch(rewardRepositoryProvider);
      return repo.getMyRewardsStream();
    },
    loading: () => const Stream.empty(), // Или можно вернуть поток с ошибкой, но лучше пустой
    error: (_, __) => const Stream.empty(),
  );
});

final rewardControllerProvider = StateNotifierProvider<RewardController, RewardState>((ref) {
  return RewardController(ref.watch(rewardRepositoryProvider));
});

class RewardState {
  final bool isLoading;
  final String? error;

  RewardState({this.isLoading = false, this.error});

  RewardState copyWith({bool? isLoading, String? error}) {
    return RewardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RewardController extends StateNotifier<RewardState> {
  final RewardRepository _repo;

  RewardController(this._repo) : super(RewardState());

  // // Исправлено: создаем объект Reward внутри контроллера
  // Future<bool> addReward(RewardType type, String title, String description, int costInStars) async {
  //   state = state.copyWith(isLoading: true, error: null);
  //   try {
  //     final newReward = Reward(
  //       id: '', // ID сгенерируется в Firestore
  //       parentId: '', // Репозиторий сам подставит текущий UID
  //       type: type,
  //       title: title,
  //       description: description,
  //       costInStars: costInStars, // Используем правильное имя поля
  //       createdAt: DateTime.now(),
  //     );
  //     await _repo.addReward(newReward);
  //     state = state.copyWith(isLoading: false);
  //     return true;
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
  //     return false;
  //   }
  // }

  Future<bool> addReward(Reward reward) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.addReward(reward);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
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
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> deleteReward(String id) async {
    try {
      await _repo.deleteReward(id);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// --- SCREEN ---

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _RewardsContent(user: user);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Ошибка: $err'))),
    );
  }
}

class _RewardsContent extends ConsumerStatefulWidget {
  final UserProfile user;

  const _RewardsContent({required this.user});

  @override
  ConsumerState<_RewardsContent> createState() => _RewardsContentState();
}

class _RewardsContentState extends ConsumerState<_RewardsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rewardControllerProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(rewardControllerProvider);
    final rewardsAsync = ref.watch(myRewardsProvider);

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          ref.read(rewardControllerProvider.notifier).clearError();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Магазин наград (${widget.user.displayName})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Управление наградами',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : () => _showRewardDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Создать награду'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: rewardsAsync.when(
                data: (rewards) {
                  if (rewards.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, size: 64, color: theme.disabledColor),
                          const SizedBox(height: 16),
                          Text('Наград пока нет', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          Text('Создайте первую награду, чтобы мотивировать ребенка!', 
                               style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                               textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: rewards.length,
                    itemBuilder: (ctx, i) {
                      final reward = rewards[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: _getRewardIcon(reward.type, reward.costInStars ?? 0),
                          title: Text(reward.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reward.description),
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${reward.costInStars} звезд', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (reward.type == RewardType.screenTime && reward.durationMinutes != null) ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.timer, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text('${reward.durationMinutes} мин', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ]),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showRewardDialog(context, ref, reward: reward),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, ref, reward.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка загрузки: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getRewardIcon(RewardType type, int value) {
    IconData iconData;
    Color bgColor;

    switch (type) {
      case RewardType.points:
        iconData = Icons.star;
        bgColor = Colors.green;
        break;
      case RewardType.gift:
        iconData = Icons.card_giftcard;
        bgColor = Colors.purple;
        break;
      case RewardType.screenTime:
        iconData = Icons.timer;
        bgColor = Colors.blue;
        break;
    }

    return CircleAvatar(
      backgroundColor: bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: Colors.white, size: 20),
          // Отображаем значение, если оно больше 0 или всегда
          if (value > 0) 
            Text('$value', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showRewardDialog(BuildContext context, WidgetRef ref, {Reward? reward}) {
    final titleCtrl = TextEditingController(text: reward?.title ?? '');
    final descCtrl = TextEditingController(text: reward?.description ?? '');
    final costCtrl = TextEditingController(text: reward?.costInStars.toString() ?? '');
    final durationCtrl = TextEditingController(text: reward?.durationMinutes?.toString() ?? '');
    final imageUrlCtrl = TextEditingController(text: reward?.imageUrl ?? '');
    RewardType selectedType = reward?.type ?? RewardType.points;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(reward == null ? 'Новая награда' : 'Редактировать награду'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<RewardType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Тип награды'),
                  items: const [
                    DropdownMenuItem(value: RewardType.points, child: Text('Баллы / Звезды')),
                    DropdownMenuItem(value: RewardType.gift, child: Text('Реальный подарок')),
                    DropdownMenuItem(value: RewardType.screenTime, child: Text('Время гаджета')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название')),
                const SizedBox(height: 16),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Описание'), maxLines: 2),
                const SizedBox(height: 16),
                TextField(
                  controller: costCtrl,
                  decoration: const InputDecoration(labelText: 'Стоимость (звезды)', prefixIcon: Icon(Icons.star)),
                  keyboardType: TextInputType.number,
                ),
                
                // УСЛОВНОЕ ПОЛЕ: Время
                if (selectedType == RewardType.screenTime) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationCtrl,
                    decoration: const InputDecoration(labelText: 'Длительность (минуты)', prefixIcon: Icon(Icons.timer)),
                    keyboardType: TextInputType.number,
                  ),
                ],

                // УСЛОВНОЕ ПОЛЕ: Картинка для подарка
                if (selectedType == RewardType.gift) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlCtrl,
                    decoration: const InputDecoration(labelText: 'URL картинки подарка', prefixIcon: Icon(Icons.image)),
                    keyboardType: TextInputType.url,
                  ),
                  if (imageUrlCtrl.text.isNotEmpty) ...[
                     const SizedBox(height: 8),
                     ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrlCtrl.text, height: 100, fit: BoxFit.cover)),
                  ]
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || costCtrl.text.isEmpty) return;
                // final cost = int.tryParse(costCtrl.text) ?? 0;
                final costStr = costCtrl.text.trim();
                final int cost = int.tryParse(costStr) ?? 0;
                // final duration = selectedType == RewardType.screenTime ? (int.tryParse(durationCtrl.text) ?? 0) : null;

                // Обработка длительности
                int duration = 0;
                if (selectedType == RewardType.screenTime) {
                  final durationStr = durationCtrl.text.trim();
                  duration = int.tryParse(durationStr) ?? 0;
                }

                // Обработка URL картинки
                String? imageUrl;
                if (selectedType == RewardType.gift) {
                  imageUrl = imageUrlCtrl.text.trim();
                  if (imageUrl.isEmpty) imageUrl = null;
                }
                
                final newReward = Reward(
                  id: reward?.id ?? '',
                  parentId: reward?.parentId ?? ref.read(authStateProvider).value!.uid,
                  type: selectedType,
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  costInStars: cost,
                  durationMinutes: duration,
                  imageUrl: imageUrl,
                  createdAt: reward?.createdAt ?? DateTime.now(),
                );

                bool success;
                if (reward == null) {
                  success = await ref.read(rewardControllerProvider.notifier).addReward(newReward);
                } else {
                  success = await ref.read(rewardControllerProvider.notifier).updateReward(newReward);
                }

                if (success && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить награду?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(rewardControllerProvider.notifier).deleteReward(id);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}