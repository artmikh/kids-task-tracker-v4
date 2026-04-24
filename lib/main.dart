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
          GoRoute(path: '/home', name: 'home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/child-home', name: 'childHome', builder: (_, __) => const ChildHomeScreen()),
          GoRoute(path: '/family', name: 'family', builder: (context, state) => const FamilyScreen()),
        ],

        redirect: (context, state) async {
          final user = FirebaseAuth.instance.currentUser;
          final isLoggedIn = user != null;
          final currentPath = state.uri.path;
          final isLoggingIn = currentPath == '/login' || currentPath == '/register';

          // Если не залогинен -> на логин
          if (!isLoggedIn && !isLoggingIn) {
            return '/login';
          }

          // Если залогинен и на странице входа -> редирект по роли
          if (isLoggedIn && isLoggingIn) {
            // Получаем роль из Firestore (быстрый запрос)
            try {
              final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              if (doc.exists) {
                final data = doc.data();
                final role = data?['role'] as String?;
                
                if (role == 'child') {
                  return '/child-home';
                } else {
                  return '/home'; // parent по умолчанию
                }
              }
            } catch (e) {
              print('Ошибка получения роли: $e');
            }
            return '/home'; // Fallback
          }

          // Защита маршрутов: если ребенок пытается зайти на /home -> кидаем на /child-home
          if (isLoggedIn && currentPath == '/home') {
             try {
              final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final role = doc.data()?['role'] as String?;
              if (role == 'child') return '/child-home';
            } catch (_) {}
          }

          // Защита маршрутов: если родитель пытается зайти на /child-home -> кидаем на /home
          if (isLoggedIn && currentPath == '/child-home') {
             try {
              final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final role = doc.data()?['role'] as String?;
              if (role != 'child') return '/home';
            } catch (_) {}
          }

          return null;
        },
      ),
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