import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // Для StreamSubscription

// Импорт темы
import 'core/theme/app_theme.dart';

// Импорт экранов
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/auth/presentation/auth_provider.dart';

// Конфигурация для веба (заглушка для эмуляторов)
final FirebaseOptions webOptions = const FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:123456789:web:abcdef',
  messagingSenderId: '123456789',
  projectId: 'demo-kids-task-tracker',
  authDomain: 'localhost',
  storageBucket: 'localhost',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase с явными опциями для Веба
  await Firebase.initializeApp(
    options: webOptions, 
  );

  // Подключение к эмуляторам
  // Для Web используем localhost, для Android эмулятора - 10.0.2.2
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

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
      // darkTheme убран, так как его нет в AppTheme
      
      routerConfig: GoRouter(
        refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
        initialLocation: '/login',
        
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
        ],

        redirect: (context, state) {
          final isLoggedIn = FirebaseAuth.instance.currentUser != null;
          // Исправлено: state.uri.path вместо state.location
          final currentPath = state.uri.path;
          final isLoggingIn = currentPath == '/login' || currentPath == '/register';

          if (!isLoggedIn && !isLoggingIn) {
            return '/login';
          }

          if (isLoggedIn && isLoggingIn) {
            return '/home';
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
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}