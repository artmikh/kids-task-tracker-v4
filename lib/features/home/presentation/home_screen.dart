import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../family/data/family_repository.dart';
import '../../family/presentation/family_provider.dart';
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

        // Если ребенок - показываем заглушку (или отдельный экран ребенка в будущем)
        if (user.role == UserRole.child) {
          return _ChildHomeView(user: user);
        }

        // Если родитель - показываем список детей
        return _ParentHomeView(user: user);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Ошибка: $err'))),
    );
  }
}

// --- ВИД ДЛЯ РОДИТЕЛЯ ---

class _ParentHomeView extends ConsumerStatefulWidget {
  final UserProfile user;

  const _ParentHomeView({required this.user});

  @override
  ConsumerState<_ParentHomeView> createState() => _ParentHomeViewState();
}

class _ParentHomeViewState extends ConsumerState<_ParentHomeView> {
  @override
  void initState() {
    super.initState();
    // Refresh списка детей при каждом появлении экрана
    Future.microtask(() => ref.invalidate(myChildrenProvider));
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(myChildrenProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Привет, ${widget.user.displayName}!'),
        actions: [
          // КНОПКА ВЫХОДА
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
              'Ваши дети:',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: childrenAsync.when(
                 data: (children) {
                  if (children.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80, color: theme.disabledColor),
                          const SizedBox(height: 16),
                          Text('Список детей пуст', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/family'),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Пригласить ребенка'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
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
                    itemBuilder: (ctx, i) {
                      final child = children[i];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            context.push('/tasks/${child.uid}', extra: child);
                            // ScaffoldMessenger.of(ctx).showSnackBar(
                            //   SnackBar(content: Text('Профиль: ${child.displayName}. Скоро здесь будут задачи!')),
                            // );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: theme.primaryColor.withOpacity(0.1),
                                child: (child.avatarUrl != null && child.avatarUrl!.isNotEmpty)
                                    ? ClipOval(child: Image.network(child.avatarUrl!, fit: BoxFit.cover))
                                    : Icon(Icons.child_care, size: 35, color: theme.primaryColor),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                child.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                                  Text(
                                    '${child.stars}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/family'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}

// --- ВИД ДЛЯ РЕБЕНКА (Заглушка) ---

class _ChildHomeView extends StatelessWidget {
  final UserProfile user;

  const _ChildHomeView({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Привет, ${user.displayName}!'),
        actions: [
           // У ребенка тоже может быть доступ к своим наградам (потратит звезды)
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'Мои награды',
            onPressed: () {
               // Пока просто заглушка, позже сделаем экран "Мои покупки"
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Раздел "Мои награды" в разработке')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Выход
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 100, color: Colors.amber),
            const SizedBox(height: 24),
            Text('Экран ребенка', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text('Здесь будет список задач и канбан-доска.', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/family'),
              child: const Text('Моя семья'),
            ),
          ],
        ),
      ),
    );
  }
}