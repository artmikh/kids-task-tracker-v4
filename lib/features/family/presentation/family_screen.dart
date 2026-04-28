import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/family_repository.dart';
import '../domain/family_invitation.dart';
import '../../user/domain/user_profile.dart';
import '../../auth/presentation/auth_provider.dart';

// --- Провайдеры ---

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

// Провайдер входящих приглашений (зависит от authState, чтобы сбрасываться при смене юзера)
final incomingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  // Следим за состоянием авторизации, чтобы пересоздать стрим при смене пользователя
  final userAsync = ref.watch(authStateProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(familyRepositoryProvider).getIncomingInvitationsStream();
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Провайдер исходящих приглашений
final outgoingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(familyRepositoryProvider).getOutgoingInvitationsStream();
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Провайдер списка детей (для родителя)
final myChildrenProvider = StreamProvider<List<UserProfile>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.when(
    data: (user) {
      if (user == null || user.role != UserRole.parent) return Stream.value([]);
      return ref.watch(familyRepositoryProvider).getMyChildrenStream();
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Провайдер списка родителей (для ребенка)
final myParentsProvider = StreamProvider<List<UserProfile>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.when(
    data: (user) {
      if (user == null || user.role != UserRole.child) return Stream.value([]);
      return ref.watch(familyRepositoryProvider).getMyParentsStream();
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Контроллер действий
final familyControllerProvider = StateNotifierProvider<FamilyController, FamilyState>((ref) {
  return FamilyController(ref.watch(familyRepositoryProvider));
});

class FamilyState {
  final bool isLoading;
  final String? error;

  FamilyState({this.isLoading = false, this.error});

  FamilyState copyWith({bool? isLoading, String? error}) {
    return FamilyState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FamilyController extends StateNotifier<FamilyState> {
  final FamilyRepository _repo;

  FamilyController(this._repo) : super(FamilyState());

  Future<bool> sendInvitation(String email, InvitationType type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.sendInvitation(email, type);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> acceptInvitation(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.acceptInvitation(id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> rejectInvitation(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.rejectInvitation(id);
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

// --- Экран ---

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _FamilyContent(user: user);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Ошибка: $err'))),
    );
  }
}

class _FamilyContent extends ConsumerStatefulWidget {
  final UserProfile user;

  const _FamilyContent({required this.user});

  @override
  ConsumerState<_FamilyContent> createState() => _FamilyContentState();
}

class _FamilyContentState extends ConsumerState<_FamilyContent> {
  @override
  void initState() {
    super.initState();
    // Очищаем ошибки контроллера при создании виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyControllerProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(familyControllerProvider);
    final isParent = widget.user.role == UserRole.parent;

    // Показываем ошибку, если она возникла в контроллере
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          ref.read(familyControllerProvider.notifier).clearError();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isParent ? 'Моя семья (Родитель)' : 'Моя семья (Ребенок)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // Кнопка НАЗАД
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
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
              isParent ? 'Управление детьми' : 'Мои родители',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Кнопка добавления
            if (isParent)
              ElevatedButton.icon(
                onPressed: state.isLoading 
                  ? null 
                  : () => _showInviteDialog(context, InvitationType.parentToChild),
                icon: const Icon(Icons.person_add),
                label: const Text('Пригласить ребенка'),
              )
            else
              ElevatedButton.icon(
                onPressed: state.isLoading 
                  ? null 
                  : () => _showInviteDialog(context, InvitationType.childToParent),
                icon: const Icon(Icons.person_add),
                label: const Text('Пригласить родителя'),
              ),
            
            const SizedBox(height: 24),

            // Основной контент
            Expanded(
              child: isParent 
                ? _buildParentView(theme) 
                : _buildChildView(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentView(ThemeData theme) {
    final childrenAsync = ref.watch(myChildrenProvider);
    final outgoingAsync = ref.watch(outgoingInvitationsProvider);

    return Column(
      children: [
        // Секция исходящих приглашений
        outgoingAsync.when(
          data: (invites) {
            if (invites.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ожидает подтверждения:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...invites.map((invite) => Card(
                  child: ListTile(
                    title: Text('Приглашение для ${invite.toEmail}'),
                    subtitle: const Text('Статус: Ожидает'),
                    trailing: const Icon(Icons.hourglass_empty, color: Colors.orange),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Ошибка: $e'),
        ),

        // Секция подключенных детей
        childrenAsync.when(
          data: (children) {
            if (children.isEmpty) {
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text('Нет привязанных детей', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              );
            }
            return Expanded(
              child: ListView.builder(
                itemCount: children.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(children[i].displayName.isNotEmpty ? children[i].displayName[0] : '?')),
                    title: Text(children[i].displayName),
                    subtitle: Text(children[i].email),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                         ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Удаление связи пока не реализовано')));
                      },
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка загрузки: $e')),
        ),
      ],
    );
  }

  Widget _buildChildView(ThemeData theme) {
    final parentsAsync = ref.watch(myParentsProvider);
    final incomingAsync = ref.watch(incomingInvitationsProvider);

    return Column(
      children: [
        // Секция входящих приглашений
        incomingAsync.when(
          data: (invites) {
            if (invites.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Входящие приглашения:', style: theme.textTheme.titleMedium?.copyWith(color: Colors.orange)),
                const SizedBox(height: 8),
                ...invites.map((invite) => Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    title: Text('От: ${invite.fromName}'),
                    subtitle: Text('Email: ${invite.toEmail}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            final success = await ref.read(familyControllerProvider.notifier).acceptInvitation(invite.id);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Приглашение принято!')));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            final success = await ref.read(familyControllerProvider.notifier).rejectInvitation(invite.id);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Приглашение отклонено')));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Ошибка: $e'),
        ),

        // Секция подключенных родителей
        parentsAsync.when(
          data: (parents) {
            if (parents.isEmpty) {
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text('Нет привязанных родителей', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              );
            }
            return Expanded(
              child: ListView.builder(
                itemCount: parents.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(parents[i].displayName.isNotEmpty ? parents[i].displayName[0] : '?')),
                    title: Text(parents[i].displayName),
                    subtitle: Text(parents[i].email),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка загрузки: $e')),
        ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context, InvitationType type) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == InvitationType.parentToChild ? 'Пригласить ребенка' : 'Пригласить родителя'),
        content: TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(labelText: 'Email пользователя', hintText: 'example@mail.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              
              final success = await ref.read(familyControllerProvider.notifier).sendInvitation(email, type);
              if (success && mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Приглашение отправлено!')));
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}