class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final bool isParent; // true = родитель, false = ребенок (упрощенно)

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.isParent = true,
  });

  factory AppUser.fromFirebase(firebaseUser) {
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      isParent: true, // По умолчанию считаем входящего родителем
    );
  }
}