import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/family_repository.dart';
import '../domain/family_invitation.dart';
import '../../user/domain/user_profile.dart';
import '../../auth/presentation/auth_provider.dart';

// ... (Провайдеры остаются без изменений, см. предыдущий код) ...
final familyRepositoryProvider = Provider<FamilyRepository>((ref) => FamilyRepository());
final incomingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) => ref.watch(familyRepositoryProvider).getIncomingInvitationsStream());
final outgoingInvitationsProvider = StreamProvider<List<FamilyInvitation>>((ref) => ref.watch(familyRepositoryProvider).getOutgoingInvitationsStream());
final myChildrenProvider = StreamProvider<List<UserProfile>>((ref) => ref.watch(familyRepositoryProvider).getMyChildrenStream());
final myParentsProvider = StreamProvider<List<UserProfile>>((ref) => ref.watch(familyRepositoryProvider).getMyParentsStream());
final familyControllerProvider = StateNotifierProvider<FamilyController, FamilyState>((ref) => FamilyController(ref.watch(familyRepositoryProvider)));

class FamilyState {
  final bool isLoading;
  final String? error;
  FamilyState({this.isLoading = false, this.error});
  FamilyState copyWith({bool? isLoading, String? error}) => FamilyState(isLoading: isLoading ?? this.isLoading, error: error);
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
  
  void clearError() => state = state.copyWith(error: null);
}

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return _FamilyContent(user: user, isParent: user.role == UserRole.parent);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Ошибка: $err'))),
    );
  }
}

class _FamilyContent extends ConsumerStatefulWidget {
  final UserProfile user;
  final bool isParent;
  const _FamilyContent({required this.user, required this.isParent});

  @override
  ConsumerState<_FamilyContent> createState() => _FamilyContentState();
}

class _FamilyContentState extends ConsumerState<_FamilyContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(familyControllerProvider);

    // Обработка ошибок контроллера
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: Colors.red, action: SnackBarAction(label: 'OK', onPressed: () => ref.read(familyControllerProvider.notifier).clearError())),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isParent ? 'Семья (Родитель)' : 'Семья (Ребенок)'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Выйти', onPressed: () => ref.read(authRepositoryProvider).signOut()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isParent ? 'Управление детьми' : 'Мои родители', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : () => _showInviteDialog(context, InvitationType.values.firstWhere((e) => e.name == (widget.isParent ? 'parentToChild' : 'childToParent'))),
              icon: const Icon(Icons.person_add),
              label: Text(widget.isParent ? 'Пригласить ребенка' : 'Пригласить родителя'),
            ),
            const SizedBox(height: 24),
            Expanded(child: widget.isParent ? _buildParentView() : _buildChildView()),
          ],
        ),
      ),
    );
  }

  Widget _buildParentView() {
    final childrenAsync = ref.watch(myChildrenProvider);
    final outgoingAsync = ref.watch(outgoingInvitationsProvider);

    return Column(
      children: [
        // Исходящие приглашения
        outgoingAsync.when(
          data: (invites) {
            if (invites.isEmpty) return const SizedBox.shrink();
            return Card(
              color: Colors.orange.shade50,
              child: ListTile(
                title: const Text('Ожидает подтверждения', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${invites.length} приглашений'),
                trailing: const Icon(Icons.hourglass_empty),
                onTap: () => _showInvitesDetails(invites, 'Исходящие'),
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Ошибка: $e'),
        ),
        const SizedBox(height: 16),
        // Список детей
        Expanded(
          child: childrenAsync.when(
            data: (children) {
              if (children.isEmpty) return _emptyState('Нет привязанных детей');
              return ListView.builder(
                itemCount: children.length,
                itemBuilder: (ctx, i) => _buildUserTile(children[i], Icons.child_care),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildChildView() {
    final parentsAsync = ref.watch(myParentsProvider);
    final incomingAsync = ref.watch(incomingInvitationsProvider);
    final outgoingAsync = ref.watch(outgoingInvitationsProvider);

    return Column(
      children: [
        // Входящие приглашения
        incomingAsync.when(
          data: (invites) {
            if (invites.isEmpty) return const SizedBox.shrink();
            return Card(
              color: Colors.green.shade50,
              child: ListTile(
                title: const Text('Новые приглашения', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                subtitle: Text('${invites.length} ожидает ответа'),
                trailing: const Icon(Icons.mail, color: Colors.green),
                onTap: () => _showInvitesDetails(invites, 'Входящие'),
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Ошибка: $e'),
        ),
        const SizedBox(height: 8),
        // Исходящие приглашения (для ребенка)
        outgoingAsync.when(
          data: (invites) {
            if (invites.isEmpty) return const SizedBox.shrink();
            return Card(
              color: Colors.blue.shade50,
              child: ListTile(
                title: const Text('Отправленные приглашения', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                subtitle: Text('${invites.length} ожидают ответа'),
                trailing: const Icon(Icons.send, color: Colors.blue),
                onTap: () => _showInvitesDetails(invites, 'Отправленные'),
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Ошибка: $e'),
        ),
        const SizedBox(height: 16),
        // Список родителей
        Expanded(
          child: parentsAsync.when(
            data: (parents) {
              if (parents.isEmpty) return _emptyState('Нет привязанных родителей');
              return ListView.builder(
                itemCount: parents.length,
                itemBuilder: (ctx, i) => _buildUserTile(parents[i], Icons.people),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(UserProfile user, IconData icon) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(user.displayName.isNotEmpty ? user.displayName[0] : '?')),
        title: Text(user.displayName),
        subtitle: Text(user.email),
        trailing: Icon(icon, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 64, color: Theme.of(context).disabledColor),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ]),
    );
  }

  void _showInviteDialog(BuildContext context, InvitationType type) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == InvitationType.parentToChild ? 'Пригласить ребенка' : 'Пригласить родителя'),
        content: TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', hintText: 'email@example.com'), keyboardType: TextInputType.emailAddress),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              final success = await ref.read(familyControllerProvider.notifier).sendInvitation(emailCtrl.text.trim(), type);
              if (success && mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Приглашение отправлено')));
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  void _showInvitesDetails(List<FamilyInvitation> invites, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: invites.length,
            itemBuilder: (ctx, i) {
              final invite = invites[i];
              return ListTile(
                title: Text(invite.fromName),
                subtitle: Text('${invite.toEmail}\nСтатус: ${invite.status.name}'),
                trailing: invite.status == InvitationStatus.pending && title == 'Входящие'
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () async {
                          await ref.read(familyControllerProvider.notifier).acceptInvitation(invite.id);
                          if (mounted) Navigator.pop(ctx);
                        }),
                        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () async {
                          await ref.read(familyControllerProvider.notifier).rejectInvitation(invite.id);
                          if (mounted) Navigator.pop(ctx);
                        }),
                      ])
                    : null,
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть'))],
      ),
    );
  }
}