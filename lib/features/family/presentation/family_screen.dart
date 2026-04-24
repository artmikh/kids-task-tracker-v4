import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import 'family_provider.dart';
import '../../user/domain/user_profile.dart';
import '../domain/family_invitation.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider); // Из auth_provider
    final theme = Theme.of(context);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final isParent = user.role == UserRole.parent;

        return Scaffold(
          appBar: AppBar(
            title: Text(isParent ? 'Мои дети' : 'Моя семья'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: isParent ? 'Пригласить ребенка' : 'Пригласить родителя',
                onPressed: () => _showInviteDialog(context, ref, isParent),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Блок уведомлений об успехе/ошибке
                _buildStatusMessages(ref),
                
                Expanded(
                  child: isParent 
                    ? _buildParentsView(context, ref) // Родитель видит своих детей
                    : _buildChildrenView(context, ref), // Ребенок видит родителей + приглашения
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Ошибка: $err'))),
    );
  }

  Widget _buildStatusMessages(WidgetRef ref) {
    final state = ref.watch(familyControllerProvider);
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
          // behavior: SnackBarBehavior.static,
          action: SnackBarAction(label: 'OK', onPressed: () => ref.read(familyControllerProvider.notifier).clearMessages()),
        ),
      );
    }
    if (state.successMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SnackBar(
          content: Text(state.successMessage!),
          backgroundColor: Colors.green,
          // behavior: SnackBarBehavior.static,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(label: 'OK', onPressed: () => ref.read(familyControllerProvider.notifier).clearMessages()),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ВИД ДЛЯ РОДИТЕЛЯ: Список детей + исходящие приглашения
  Widget _buildParentsView(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(myChildrenProvider);
    final outgoingAsync = ref.watch(outgoingInvitationsProvider);

    return Column(
      children: [
        // Заголовок
        Align(alignment: Alignment.centerLeft, child: Text('Ваши дети:', style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height: 8),
        
        // Список детей
        SizedBox(
          height: 200,
          child: childrenAsync.when(
            data: (children) => children.isEmpty 
              ? const Center(child: Text('Пока нет привязанных детей'))
              : ListView.builder(
                  itemCount: children.length,
                  itemBuilder: (_, i) => _UserTile(user: children[i], roleLabel: 'Ребенок'),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
          ),
        ),
        
        const Divider(height: 32),
        
        // Заголовок приглашений
        Align(alignment: Alignment.centerLeft, child: Text('Ожидают подтверждения:', style: Theme.of(context).textTheme.titleSmall)),
        
        // Список исходящих приглашений
        Expanded(
          child: outgoingAsync.when(
            data: (invites) => invites.isEmpty
              ? const Center(child: Text('Нет активных приглашений'))
              : ListView.builder(
                  itemCount: invites.length,
                  itemBuilder: (_, i) => _InvitationTile(invitation: invites[i], isIncoming: false, ref: ref),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
          ),
        ),
      ],
    );
  }

  // ВИД ДЛЯ РЕБЕНКА: Список родителей + входящие приглашения
  Widget _buildChildrenView(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(myParentsProvider);
    final incomingAsync = ref.watch(incomingInvitationsProvider);

    return Column(
      children: [
        // Заголовок родителей
        Align(alignment: Alignment.centerLeft, child: Text('Ваши родители:', style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height: 8),

        // Список родителей
        SizedBox(
          height: 200,
          child: parentsAsync.when(
            data: (parents) => parents.isEmpty
              ? const Center(child: Text('Пока нет привязанных родителей'))
              : ListView.builder(
                  itemCount: parents.length,
                  itemBuilder: (_, i) => _UserTile(user: parents[i], roleLabel: 'Родитель'),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
          ),
        ),

        const Divider(height: 32),

        // Заголовок приглашений
        Align(alignment: Alignment.centerLeft, child: Text('Входящие приглашения:', style: Theme.of(context).textTheme.titleSmall)),

        // Список входящих приглашений
        Expanded(
          child: incomingAsync.when(
            data: (invites) => invites.isEmpty
              ? const Center(child: Text('Нет новых приглашений'))
              : ListView.builder(
                  itemCount: invites.length,
                  itemBuilder: (_, i) => _InvitationTile(invitation: invites[i], isIncoming: true, ref: ref),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
          ),
        ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, bool isParent) {
    final emailCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isParent ? 'Пригласить ребенка' : 'Пригласить родителя'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email пользователя', hintText: 'example@mail.com'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              
              final type = isParent ? InvitationType.parentToChild : InvitationType.childToParent;
              final success = await ref.read(familyControllerProvider.notifier).sendInvitation(email, type);
              
              if (success && ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}

// Виджет карточки пользователя
class _UserTile extends StatelessWidget {
  final UserProfile user;
  final String roleLabel;

  const _UserTile({required this.user, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text(user.displayName[0].toUpperCase())),
        title: Text(user.displayName),
        subtitle: Text(user.email),
        trailing: Chip(label: Text(roleLabel, style: const TextStyle(fontSize: 12, color: Colors.white)), backgroundColor: Colors.blue),
      ),
    );
  }
}

// Виджет карточки приглашения
class _InvitationTile extends StatelessWidget {
  final FamilyInvitation invitation;
  final bool isIncoming;
  final WidgetRef ref;

  const _InvitationTile({required this.invitation, required this.isIncoming, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.mail_outline, color: Colors.orange),
        title: Text(isIncoming ? 'От: ${invitation.fromName}' : 'Кому: ${invitation.toEmail}'),
        subtitle: Text('Статус: Ожидает'),
        trailing: isIncoming
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => ref.read(familyControllerProvider.notifier).acceptInvitation(invitation.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => ref.read(familyControllerProvider.notifier).rejectInvitation(invitation.id),
                  ),
                ],
              )
            : const Text('Ожидает...', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}