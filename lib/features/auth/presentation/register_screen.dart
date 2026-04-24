import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../user/domain/user_profile.dart'; // Импортируем модель профиля с UserRole

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  // Используем тип UserRole вместо String
  UserRole _selectedRole = UserRole.parent; 
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authControllerProvider.notifier).clearError();

    // Передаем UserRole напрямую
    final success = await ref.read(authControllerProvider.notifier).signUp(
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _nameCtrl.text.trim(),
      _selectedRole, 
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authControllerProvider).error ?? 'Ошибка')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.person_add, size: 60, color: theme.primaryColor),
                const SizedBox(height: 24),
                
                // Выбор роли
                Text('Кто вы?', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SegmentedButton<UserRole>(
                  segments: const [
                    // Используем значения enum UserRole, а не строки
                    ButtonSegment(value: UserRole.parent, label: Text('Родитель'), icon: Icon(Icons.people)),
                    ButtonSegment(value: UserRole.child, label: Text('Ребенок'), icon: Icon(Icons.child_care)),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (Set<UserRole> newSelection) {
                    setState(() {
                      _selectedRole = newSelection.first;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: 'Ваше имя', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v!.isEmpty ? 'Введите имя' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v!.isEmpty || !v.contains('@') ? 'Введите корректный email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.length < 6 ? 'Минимум 6 символов' : null,
                ),
                const SizedBox(height: 24),
                if (state.error != null) Text(state.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: state.isLoading ? const CircularProgressIndicator() : const Text('ЗАРЕГИСТРИРОВАТЬСЯ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}