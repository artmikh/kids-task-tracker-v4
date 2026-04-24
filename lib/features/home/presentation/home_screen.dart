import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../children/presentation/children_provider.dart';
import '../../children/domain/child_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final childrenAsync = ref.watch(childrenStreamProvider);
    final theme = Theme.of(context);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return Scaffold(
          appBar: AppBar(
            title: Text('Привет, ${user.displayName ?? "Родитель"}!'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Выйти',
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ваши дети:',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  // ИСПРАВЛЕНО: Правильный синтаксис .when(...)
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
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showAddChildDialog(context, ref),
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить первого ребенка'),
                              )
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
                          return _ChildCard(child: children[index]);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Ошибка загрузки: $err')),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddChildDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Добавить ребенка'),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Ошибка авторизации: $err'))),
    );
  }

  void _showAddChildDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddChildDialog(ref: ref),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Child child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Переход к ребенку: ${child.name} (в разработке)')),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: child.avatarUrl.isNotEmpty
                  ? ClipOval(child: Image.network(child.avatarUrl, fit: BoxFit.cover))
                  : Icon(Icons.child_care, size: 40, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              child.name,
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
                Text('${child.stars}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _AddChildDialog extends StatefulWidget {
  final WidgetRef ref;

  const _AddChildDialog({required this.ref});

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    // Теперь провайдер должен быть виден, так как импортирован в файл
    final success = await widget.ref.read(childrenControllerProvider.notifier).addChild(
      _nameCtrl.text.trim(),
      '', 
    );

    if (success && mounted) {
      Navigator.pop(context); 
    } else if (mounted) {
      final error = widget.ref.read(childrenControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Ошибка при добавлении')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый ребенок'),
      content: TextField(
        controller: _nameCtrl,
        decoration: const InputDecoration(labelText: 'Имя ребенка', hintText: 'Например, Саша'),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Создать'),
        ),
      ],
    );
  }
}