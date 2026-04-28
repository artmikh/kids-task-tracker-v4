import 'package:cloud_firestore/cloud_firestore.dart';

enum RewardType {
  points,          // Баллы (виртуальная валюта внутри приложения, если захотим расширить)
  gift,            // Реальный подарок (игрушка, поход в кино)
  screenTime,      // Время на гаджете (минуты)
  // future types: specialActivity, chooseDinner, etc.
}

class Reward {
  final String id;
  final String parentId;       // Кто создал (владелец награды)
  final String? childId;       // Если награда персональная (опционально, пока null = для всех детей)
  final String title;
  final String description;
  final RewardType type;
  final int costInStars;       // Стоимость в звездах (для screen_time и points). Для gift может быть 0 или условная цена.
  final int durationMinutes;   // Для типа screen_time (сколько минут добавляется)
  final bool isCompleted;      // Для типа gift (выполнено ли обещание)
  final DateTime createdAt;

  Reward({
    required this.id,
    required this.parentId,
    this.childId,
    required this.title,
    required this.description,
    required this.type,
    this.costInStars = 0,
    this.durationMinutes = 0,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Reward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reward(
      id: doc.id,
      parentId: data['parentId'] ?? '',
      childId: data['childId'],
      title: data['title'] ?? 'Без названия',
      description: data['description'] ?? '',
      type: RewardType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RewardType.gift,
      ),
      costInStars: data['costInStars'] ?? 0,
      durationMinutes: data['durationMinutes'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childId': childId,
      'title': title,
      'description': description,
      'type': type.name,
      'costInStars': costInStars,
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Reward copyWith({
    String? id,
    String? parentId,
    String? childId,
    String? title,
    String? description,
    RewardType? type,
    int? costInStars,
    int? durationMinutes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Reward(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      costInStars: costInStars ?? this.costInStars,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Helper для отображения иконки типа
  String get iconData {
    switch (type) {
      case RewardType.points: return '💰';
      case RewardType.gift: return '🎁';
      case RewardType.screenTime: return '📱';
    }
  }
  
  String get typeLabel {
    switch (type) {
      case RewardType.points: return 'Баллы';
      case RewardType.gift: return 'Подарок';
      case RewardType.screenTime: return 'Время гаджета';
    }
  }
}