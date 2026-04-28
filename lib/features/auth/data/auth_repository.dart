import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../user/domain/user_profile.dart'; // Путь к модели профиля

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Коллекция пользователей
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Поток изменений состояния авторизации
  /// Возвращает UserProfile, если пользователь вошел, иначе null
  Stream<UserProfile?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      // Пытаемся получить профиль из Firestore
      try {
        final doc = await _usersCollection.doc(user.uid).get();
        if (doc.exists) {
          return UserProfile.fromFirestore(doc);
        } else {
          // Если документа нет (редкий случай рассинхронизации), создаем заглушку или возвращаем null
          // В идеале здесь нужна логика восстановления, но пока вернем базовый профиль
          return UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'User',
            role: UserRole.parent, // По умолчанию родитель, если профиль потерян
            avatarUrl: user.photoURL ?? '',
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        print('Ошибка получения профиля: $e');
        return null;
      }
    });
  }

  /// Вход по email и паролю
  Future<UserProfile> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) throw Exception('User is null');
      
      // Получаем профиль из Firestore
      final doc = await _usersCollection.doc(credential.user!.uid).get();
      if (!doc.exists) {
        throw Exception('Профиль пользователя не найден в базе данных');
      }
      
      return UserProfile.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Ошибка входа');
    }
  }

  /// Регистрация нового пользователя с ролью
  Future<UserProfile> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String displayName,
    UserRole role, // Теперь принимаем enum UserRole
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) throw Exception('User is null');
      
      // Обновляем displayName в Firebase Auth
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) throw Exception('User is null after reload');

      // Создаем документ профиля в Firestore
      final newUser = UserProfile(
        uid: updatedUser.uid,
        email: updatedUser.email ?? email,
        displayName: displayName,
        role: role,
        avatarUrl: updatedUser.photoURL ?? '',
        createdAt: DateTime.now(), // Добавлено обязательное поле
      );

      await _usersCollection.doc(newUser.uid).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Ошибка регистрации');
    }
  }

  /// Выход из системы
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  /// Получение текущего профиля (синхронно, если нужно)
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final doc = await _usersCollection.doc(user.uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }
}