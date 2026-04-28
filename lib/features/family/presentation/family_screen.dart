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

// ИСПРАВЛЕНИЕ: Явно добавляем зависимость от authStateProvider.
// При смене пользователя (изменении authState) этот провайдер пересоздастся,
// заставляя стрим переподписаться на нового пользователя.
final incomingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  // Следим за состоянием авторизации, чтобы сбрасывать кэш при смене юзера
  final authState = ref.watch(authStateProvider);
  
  // Если пользователь не загружен или вышел, возвращаем пустой список
  if (authState is! AsyncData || authState.value == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(familyRepositoryProvider);
  return repo.getIncomingInvitationsStream();
});

final outgoingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) {
  // Аналогично для исходящих
  final authState = ref.watch(authStateProvider);
  
  if (authState is! AsyncData || authState.value == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(familyRepositoryProvider);
  return repo.getOutgoingInvitationsStream();
});

final myChildrenProvider = StreamProvider<List<UserProfile>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is! AsyncData || authState.value == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getMyChildrenStream();
});

final myParentsProvider = StreamProvider<List<UserProfile>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is! AsyncData || authState.value == null) {
    return Stream.value([]);
  }
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
      error: (err, _) => Scaffold(body: Center(child: Text('Ошибка авторизации: $err'))),
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
    // Очищаем ошибки при первом запуске виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(familyControllerProvider.notifier).clearError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(familyControllerProvider);
    final isParent = widget.user.role == UserRole.parent;

    // Показ ошибок
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
            Text(isParent ? 'Семья (Родитель)' : 'Семья (Ребенок)', style: const TextStyle(fontSize: 14)),
            Text(widget.user.displayName, style: const TextStyle(fontSize: 14)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (!context.canPop()) {
              context.go('/home');
            } else {
              context.pop();
            }
          },
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

            // Кнопка отправки приглашения
            ElevatedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => _showInviteDialog(context, ref, isParent ? InvitationType.parentToChild : InvitationType.childToParent),
              icon: const Icon(Icons.person_add),
              label: Text(isParent ? 'Пригласить ребенка' : 'Пригласить родителя'),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Секция входящих приглашений
                    _buildSectionTitle(theme, 'Входящие приглашения'),
                    _buildIncomingInvitations(ref, theme),
                    
                    const SizedBox(height: 20),

                    // Секция исходящих приглашений
                    _buildSectionTitle(theme, 'Исходящие приглашения'),
                    _buildOutgoingInvitations(ref, theme),

                    const SizedBox(height: 20),

                    // Секция подтвержденных связей
                    _buildSectionTitle(theme, isParent ? 'Ваши дети' : 'Ваши родители'),
                    _buildConfirmedLinks(ref, theme, isParent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildIncomingInvitations(WidgetRef ref, ThemeData theme) {
    final asyncValue = ref.watch(incomingInvitationsProvider);
    return _buildInvitationList(asyncValue, ref, theme, isIncoming: true);
  }

  Widget _buildOutgoingInvitations(WidgetRef ref, ThemeData theme) {
    final asyncValue = ref.watch(outgoingInvitationsProvider);
    return _buildInvitationList(asyncValue, ref, theme, isIncoming: false);
  }

  Widget _buildInvitationList(AsyncValue<List<FamilyInvitation>> asyncValue, WidgetRef ref, ThemeData theme, {required bool isIncoming}) {
    return asyncValue.when(
      data: (invites) {
        if (invites.isEmpty) {
          return Card(
            color: theme.cardColor.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Нет приглашений', style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
            ),
          );
        }
        return Column(
          children: invites.map((invite) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIncoming ? Colors.orange.shade100 : Colors.blue.shade100,
                  child: Icon(isIncoming ? Icons.mail : Icons.send, color: isIncoming ? Colors.orange : Colors.blue),
                ),
                title: Text(isIncoming ? 'От: ${invite.fromName}' : 'Для: ${invite.toEmail}'),
                subtitle: Text('Статус: ${_getStatusText(invite.status)}'),
                trailing: isIncoming && invite.status == InvitationStatus.pending
                    ? Row(
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
                      )
                    : Icon(
                        invite.status == InvitationStatus.pending ? Icons.hourglass_empty : Icons.check_circle,
                        color: invite.status == InvitationStatus.pending ? Colors.grey : Colors.green,
                      ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
      error: (e, _) => Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Ошибка: $e', style: const TextStyle(color: Colors.red)))),
    );
  }

  Widget _buildConfirmedLinks(WidgetRef ref, ThemeData theme, bool isParent) {
    final asyncValue = isParent ? ref.watch(myChildrenProvider) : ref.watch(myParentsProvider);

    return asyncValue.when(
      data: (profiles) {
        if (profiles.isEmpty) {
          return Card(
            color: theme.cardColor.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(isParent ? 'Нет привязанных детей' : 'Нет привязанных родителей', style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
            ),
          );
        }
        return Column(
          children: profiles.map((profile) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text(profile.displayName.isNotEmpty ? profile.displayName[0] : '?')),
                title: Text(profile.displayName),
                subtitle: Text(profile.email),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
      error: (e, _) => Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Ошибка: $e', style: const TextStyle(color: Colors.red)))),
    );
  }

  String _getStatusText(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending: return 'Ожидает';
      case InvitationStatus.accepted: return 'Принято';
      case InvitationStatus.rejected: return 'Отклонено';
      case InvitationStatus.cancelled: return 'Отменено';
    }
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