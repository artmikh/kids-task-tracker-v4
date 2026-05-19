import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../family/presentation/family_provider.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text('Привет, ${user.displayName}!'),
            actions: [
              IconButton(
                icon: const Icon(Icons.family_restroom),
                tooltip: 'Семья',
                onPressed: () => context.go('/family'),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.child_care, size: 100, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  'Это детский режим',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '${user.stars} звёзд',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/my-tasks'),
                  child: const Text('Мои задачи'),
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
}