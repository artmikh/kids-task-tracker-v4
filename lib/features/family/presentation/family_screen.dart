import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/family_repository.dart';
import '../domain/family_invitation.dart';
import '../../user/domain/user_profile.dart';
import '../../auth/presentation/auth_provider.dart';

// --- PROVIDERS ---

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

final incomingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getIncomingInvitationsStream();
});

final outgoingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getOutgoingInvitationsStream();
});

final myChildrenProvider = StreamProvider<List<UserProfile>>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getMyChildrenStream();
});

final myParentsProvider = StreamProvider<List<UserProfile>>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getMyParentsStream();
});

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

// --- SCREEN ---

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyControllerProvider.notifier).clearError();
    });
  }

  void _handleBack() {
    // Пытаемся вернуться назад через Navigator
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // Если некуда возвращаться (например, прямой заход на URL), идем на Home
      if (context.mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(familyControllerProvider);
    final isParent = widget.user.role == UserRole.parent;
    final userName = widget.user.displayName;

    // Обработка ошибок контроллера
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isParent ? 'Семья' : 'Семья', style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 16)),
            Text(userName, style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
          tooltip: 'Назад',
        ),
        actions: [
          // Кнопка выхода
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
              // GoRouter сам перенаправит на /login благодаря listenable
            },
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

            if (isParent)
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => _showInviteDialog(context, ref, InvitationType.parentToChild),
                icon: const Icon(Icons.person_add),
                label: const Text('Пригласить ребенка'),
              )
            else
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => _showInviteDialog(context, ref, InvitationType.childToParent),
                icon: const Icon(Icons.person_add),
                label: const Text('Пригласить родителя'),
              ),

            const SizedBox(height: 24),

            Expanded(
              child: isParent
                  ? _buildParentView(ref, theme)
                  : _buildChildView(ref, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentView(WidgetRef ref, ThemeData theme) {
    final childrenAsync = ref.watch(myChildrenProvider);
    final outgoingAsync = ref.watch(outgoingInvitationsProvider);

    return Column(
      children: [
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
                    subtitle: Text('Отправлено: ${invite.createdAt.day}.${invite.createdAt.month}'),
                    trailing: const Icon(Icons.hourglass_empty, color: Colors.orange),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Ошибка загрузки приглашений: $e'),
        ),

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
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка загрузки детей: $e')),
        ),
      ],
    );
  }

  Widget _buildChildView(WidgetRef ref, ThemeData theme) {
    final parentsAsync = ref.watch(myParentsProvider);
    final incomingAsync = ref.watch(incomingInvitationsProvider);
    final outgoingAsync = ref.watch(outgoingInvitationsProvider);

    return Column(
      children: [
        // Входящие приглашения
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
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Принято!')));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            final success = await ref.read(familyControllerProvider.notifier).rejectInvitation(invite.id);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Отклонено')));
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

        // Исходящие приглашения
        outgoingAsync.when(
          data: (invites) {
            if (invites.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Отправленные вами:', style: theme.textTheme.titleMedium?.copyWith(color: Colors.blue)),
                const SizedBox(height: 8),
                ...invites.map((invite) => Card(
                  child: ListTile(
                    title: Text('Для: ${invite.toEmail}'),
                    subtitle: Text('Тип: ${invite.type == InvitationType.childToParent ? "Родитель" : "Ребенок"}'),
                    trailing: const Icon(Icons.access_time, color: Colors.blue),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Ошибка: $e'),
        ),

        // Список родителей
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
          error: (e, _) => Center(child: Text('Ошибка: $e')),
        ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, InvitationType type) {
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
              if (success && ctx.mounted) {
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