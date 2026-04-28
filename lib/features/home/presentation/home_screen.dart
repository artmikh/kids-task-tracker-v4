import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../family/presentation/family_screen.dart'; // Импортируем провайдеры из family_screen
import '../../user/domain/user_profile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final isParent = user.role == UserRole.parent;

        return Scaffold(
          appBar: AppBar(
            title: Text('Привет, ${user.displayName}!'),
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
                  isParent ? 'Ваши дети:' : 'Мои задачи',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Кнопка перехода в Семью (для управления привязками)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.push('/family'),
                    icon: const Icon(Icons.family_restroom),
                    label: const Text('Управление семьей'),
                  ),
                ),

                Expanded(
                  child: isParent 
                    ? _buildParentView(ref, context) 
                    : _buildChildView(ref, context),
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

  Widget _buildParentView(WidgetRef ref, BuildContext context) {
    // Используем провайдер myChildrenProvider из family_screen.dart
    final childrenAsync = ref.watch(myChildrenProvider);

    return childrenAsync.when(
      data: (children) {
        if (children.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                Text('У вас пока нет привязанных детей', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/family'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Пригласить ребенка'),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) {
            final child = children[index];
            return _ChildCard(profile: child);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Ошибка загрузки: $err')),
    );
  }

  Widget _buildChildView(WidgetRef ref, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text('Здесь будут ваши задачи!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('(Функционал задач в разработке)', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// Карточка ребенка (использует UserProfile)
class _ChildCard extends StatelessWidget {
  final UserProfile profile;

  const _ChildCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Профиль: ${profile.displayName}. Скоро здесь будут задачи!')),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              // Безопасная работа с avatarUrl (может быть null)
              child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(profile.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.child_care, size: 40)))
                  : Icon(Icons.child_care, size: 40, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              profile.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                // Пока звезд нет в профиле, показываем 0 или можно добавить поле в UserProfile
                Text('0', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}