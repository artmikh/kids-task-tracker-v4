import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  todo,        // Нужно сделать
  inProgress,  // В процессе
  done         // Выполнено
}

class Task {
  final String id;
  final String parentId;   // Кто создал задачу
  final String childId;    // Кому задача
  final String title;
  final String description;
  final TaskStatus status;
  final int rewardStars;   // Сколько звезд дадут за выполнение
  final DateTime createdAt;
  final DateTime? completedAt; // Когда выполнили

  Task({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    required this.rewardStars,
    required this.createdAt,
    this.completedAt,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      parentId: data['parentId'] ?? '',
      childId: data['childId'] ?? '',
      title: data['title'] ?? 'Без названия',
      description: data['description'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.todo,
      ),
      rewardStars: data['rewardStars'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childId': childId,
      'title': title,
      'description': description,
      'status': status.name,
      'rewardStars': rewardStars,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  Task copyWith({
    String? id,
    String? parentId,
    String? childId,
    String? title,
    String? description,
    TaskStatus? status,
    int? rewardStars,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      rewardStars: rewardStars ?? this.rewardStars,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
  
  // Helper для отображения статуса на русском
  String get statusLabel {
    switch (status) {
      case TaskStatus.todo: return 'Нужно сделать';
      case TaskStatus.inProgress: return 'В процессе';
      case TaskStatus.done: return 'Выполнено';
    }
  }
}