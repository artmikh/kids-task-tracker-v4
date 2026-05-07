import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { parent, child }

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;
  final int stars;
  final int balance;
  final List<String> familyIds;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = UserRole.parent,
    this.avatarUrl,
    required this.createdAt,
    this.stars = 0,
    this.balance = 0,
    this.familyIds = const [],
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Без имени',
      role: (data['role'] as String?) == 'child' ? UserRole.child : UserRole.parent,
      avatarUrl: data['avatarUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stars: (data['stars'] as num?)?.toInt() ?? 0,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      familyIds: (data['familyIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'stars': stars,
      'balance': balance,
      'familyIds': familyIds,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? avatarUrl,
    DateTime? createdAt,
    int? stars,
    int? balance,
    List<String>? familyIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      stars: stars ?? this.stars,
      balance: balance ?? this.balance,
      familyIds: familyIds ?? this.familyIds,
    );
  }
}
