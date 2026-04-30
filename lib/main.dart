import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

// Импорт темы
import 'core/theme/app_theme.dart';

// Импорт экранов
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/family/presentation/family_screen.dart';
import 'features/home/presentation/home_screen.dart'; // Экран родителя
import 'features/children/presentation/child_home_screen.dart'; // Экран ребенка (создадим ниже)
import 'features/auth/presentation/auth_provider.dart';
import 'features/rewards/presentation/rewards_screen.dart';
import 'features/tasks/presentation/parent_tasks_screen.dart';
import 'features/user/domain/user_profile.dart'; // Для UserRole

// Конфигурация для веба
final FirebaseOptions webOptions = const FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:123456789:web:abcdef',
  messagingSenderId: '123456789',
  projectId: 'demo-no-project', 
  authDomain: 'localhost',
  storageBucket: 'localhost',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: webOptions);

  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);

  runApp(const ProviderScope(child: KidsTaskTrackerApp()));
}

class KidsTaskTrackerApp extends ConsumerWidget {
  const KidsTaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kids Task Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      routerConfig: GoRouter(
        refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
        initialLocation: '/login',
        
        routes: [
          GoRoute(path: '/login', name: 'login', builder: (_, __) => const LoginScreen()),
          GoRoute(path: '/register', name: 'register', builder: (_, __) => const RegisterScreen()),
          
          
        //   GoRoute(path: '/home', name: 'home', builder: (_, __) => const HomeScreen()),
        //   GoRoute(path: '/child-home', name: 'childHome', builder: (_, __) => const ChildHomeScreen()),
        //   GoRoute(path: '/family', name: 'family', builder: (context, state) => const FamilyScreen()),
        //   GoRoute(path: '/rewards', name: 'rewards', builder: (context, state) => const RewardsScreen()),
        // ],

          // Защищенный маршрут-оболочка (ShellRoute)
          ShellRoute(
            builder: (context, state, child) {
              return MainShell(child: child);
            },
            routes: [
              // Маршруты внутри оболочки
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
              ),
              GoRoute(
                path: '/family',
                name: 'family',
                pageBuilder: (context, state) => const NoTransitionPage(child: FamilyScreen()),
              ),
              GoRoute(
                path: '/rewards',
                name: 'rewards',
                pageBuilder: (context, state) => const NoTransitionPage(child: RewardsScreen()),
              ),
              GoRoute(
                path: '/child-home',
                name: 'childHome',
                pageBuilder: (context, state) => const NoTransitionPage(child: ChildHomeScreen()),
              ),
              GoRoute(
                path: '/tasks/:childId',
                name: 'parentTasks',
                pageBuilder: (context, state) {
                  final childId = state.pathParameters['childId']!;
                  // Extra данные можно достать через state.extra, если передавали объект, 
                  // но для имени можно передать просто строку или достать из репозитория. 
                  // Для простоты передадим имя через extra при push, а здесь кастуем.
                  final childName = (state.extra as UserProfile?)?.displayName ?? 'Ребенок';
                  
                  return NoTransitionPage(
                    child: ParentTasksScreen(childId: childId, childName: childName),
                  );
                },
              ),
              // Добавьте сюда будущие экраны ребенка (магазин, профиль)
            ],
          ),
        ],

        redirect: (context, state) async {
          final user = FirebaseAuth.instance.currentUser;
          final isLoggedIn = user != null;
          final currentPath = state.uri.path;
          final isLoggingIn = currentPath == '/login' || currentPath == '/register';
          final isShellRoute = currentPath.startsWith('/home') || 
                               currentPath.startsWith('/family') || 
                               currentPath.startsWith('/rewards') ||
                               currentPath.startsWith('/child-home');

          if (!isLoggedIn && !isLoggingIn) return '/login';
          
          if (isLoggedIn && isLoggingIn) {
            try {
              final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final role = doc.data()?['role'] as String?;
              return role == 'child' ? '/child-home' : '/home';
            } catch (_) {}
            return '/home';
          }

          // Проверка прав доступа внутри оболочки
          if (isLoggedIn && isShellRoute) {
            try {
              final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final role = doc.data()?['role'] as String?;
              
              // Ребенок не должен видеть экраны родителя (ДОМАШНИЙ и НАГРАДЫ)
              // /family оставлен доступным для всех!
              if (role == 'child' && (currentPath == '/home' || currentPath == '/rewards')) {
                 return '/child-home';
              }
              
              // Родитель не должен видеть экраны ребенка
              if (role != 'child' && currentPath == '/child-home') {
                 return '/home';
              }
            } catch (_) {}
          }

          return null;
        },
      ),
    );
  }
}

// --- ОБЛОЧКА С НИЖНИМ МЕНЮ ---

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          
          final isParent = user.role == UserRole.parent;
          
          // Определяем пункты меню в зависимости от роли
          // ИЗМЕНЕНИЕ: Добавлена вкладка "Семья" для ребенка
          final List<NavigationDestination> destinations = isParent
              ? const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Дети'),
                  NavigationDestination(icon: Icon(Icons.family_restroom_outlined), selectedIcon: Icon(Icons.family_restroom), label: 'Семья'),
                  NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), selectedIcon: Icon(Icons.card_giftcard), label: 'Награды'),
                ]
              : const [
                  NavigationDestination(icon: Icon(Icons.task_outlined), selectedIcon: Icon(Icons.task), label: 'Задачи'),
                  NavigationDestination(icon: Icon(Icons.family_restroom_outlined), selectedIcon: Icon(Icons.family_restroom), label: 'Семья'), // Новая вкладка
                  NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Магазин'),
                  NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Профиль'),
                ];

          // Маппинг путей для индексации
          final List<String> parentPaths = ['/home', '/family', '/rewards'];
          // ИЗМЕНЕНИЕ: Добавлен путь '/family' для ребенка (индекс 1)
          final List<String> childPaths = ['/child-home', '/family', '/child-shop', '/child-profile']; 
          
          final state = GoRouterState.of(context);
          final currentLocation = state.uri.path;
          
          int selectedIndex = 0;
          
          if (isParent) {
            selectedIndex = parentPaths.indexWhere((p) => currentLocation.startsWith(p));
            if (selectedIndex == -1) selectedIndex = 0;
          } else {
            // Ищем индекс текущего пути в массиве childPaths
            selectedIndex = childPaths.indexWhere((p) => currentLocation.startsWith(p));
            if (selectedIndex == -1) selectedIndex = 0;
          }

          return Scaffold(
            body: widget.child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                if (isParent) {
                  context.go(parentPaths[index]);
                } else {
                    /// Логика для ребенка
                  if (index < childPaths.length) {
                    final path = childPaths[index];
                    // Если путь ведет на несуществующий экран (магазин/профиль), показываем заглушку
                    if (path == '/child-shop' || path == '/child-profile') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Раздел "${destinations[index].label}" в разработке')),
                      );
                      // Остаемся на текущей странице или возвращаем на задачи, но лучше просто показать сообщение
                      // и не менять маршрут, чтобы индекс в меню не скакал, если мы не меняем selectedIndex принудительно
                      // Но NavigationBar сам сменит индекс. Чтобы вернуть назад, можно сделать go на текущий.
                      // Для простоты пока оставим переход, но экран будет пустой или ошибкой, либо можно сделать редирект обратно:
                      // context.go(currentLocation); 
                    } else {
                      context.go(path);
                    }
                  }
                }
              },
              destinations: destinations,
            ),
          );
        },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Ошибка: $e'))),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}