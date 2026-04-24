import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((user) => 
      user != null ? AppUser.fromFirebase(user) : null
    );
  }

  Future<AppUser> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) throw Exception('User is null');
      return AppUser.fromFirebase(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Ошибка входа');
    }
  }

  Future<AppUser> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) throw Exception('User is null');
      
      // Обновляем профиль (имя)
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User is null after reload');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'role': 'parent', // По умолчанию родитель
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return AppUser.fromFirebase(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Ошибка регистрации');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}