import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  backlog,     // Пул задач — родитель создал, но ещё не назначил на период
  todo,        // Нужно сделать — назначено на текущий период
  inProgress,  // В процессе
  review,      // На проверке
  done         // Готово (подтверждено родителем)
}

class Task {
  final String id;
  final String parentId;   // Кто создал задачу
  final String childId;    // Кому задача
  final String title;
  final String description;
  final TaskStatus status;
  final int rewardStars;   // Сколько звезд дадут за выполнение
  final int revisionCount; // Сколько раз возвращали на доработку
  final DateTime createdAt;
  final DateTime? completedAt; // Когда выполнили (подтвердил родитель)
  final DateTime? submittedAt; // Когда ребёнок отправил на проверку

  Task({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.backlog,
    required this.rewardStars,
    this.revisionCount = 0,
    required this.createdAt,
    this.completedAt,
    this.submittedAt,
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
      revisionCount: data['revisionCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
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
      'revisionCount': revisionCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
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
    int? revisionCount,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? submittedAt,
  }) {
    return Task(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      rewardStars: rewardStars ?? this.rewardStars,
      revisionCount: revisionCount ?? this.revisionCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
  
  // Helper для отображения статуса на русском
    String get statusLabel {
    switch (status) {
      case TaskStatus.backlog: return 'Пул задач';
      case TaskStatus.todo: return 'Нужно сделать';
      case TaskStatus.inProgress: return 'В процессе';
      case TaskStatus.review: return 'На проверке';
      case TaskStatus.done: return 'Готово';
    }
  }

  // Помечена ли задача как доработка
  bool get isRevision => revisionCount > 0;
}