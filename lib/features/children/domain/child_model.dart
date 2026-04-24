import 'package:cloud_firestore/cloud_firestore.dart';

class Child {
  final String id; // ID документа в Firestore
  final String parentId; // UID родителя из Auth
  final String name;
  final String avatarUrl; // Ссылка на картинку или ключ ассета
  final int stars; // Баланс звезд (наград)
  final DateTime createdAt;

  Child({
    required this.id,
    required this.parentId,
    required this.name,
    this.avatarUrl = '', // По умолчанию пустой или стандартный
    this.stars = 0,
    required this.createdAt,
  });

  // Конвертация из Firestore документа в объект
  factory Child.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Child(
      id: doc.id,
      parentId: data['parentId'] ?? '',
      name: data['name'] ?? 'Без имени',
      avatarUrl: data['avatarUrl'] ?? '',
      stars: data['stars'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Конвертация объекта в Map для записи в Firestore
  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'avatarUrl': avatarUrl,
      'stars': stars,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Копирование объекта с изменениями (удобно для обновлений)
  Child copyWith({
    String? id,
    String? parentId,
    String? name,
    String? avatarUrl,
    int? stars,
    DateTime? createdAt,
  }) {
    return Child(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      stars: stars ?? this.stars,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}