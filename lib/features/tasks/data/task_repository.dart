import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/task_model.dart';
import '../../user/domain/user_profile.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TaskRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('tasks');

  String? get currentUid => _auth.currentUser?.uid;

  /// Поток задач для конкретного ребенка
  Stream<List<Task>> getTasksForChildStream(String childId) {
    return _tasksCollection
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  /// Создание новой задачи
  Future<void> createTask(
    String childId,
    String title,
    String description,
    int rewardStars,
  ) async {
    final parentId = currentUid;
    if (parentId == null) throw Exception('Необходимо войти как родитель');

    final newTask = Task(
      id: '',
      parentId: parentId,
      childId: childId,
      title: title,
      description: description,
      rewardStars: rewardStars,
      createdAt: DateTime.now(),
      status: TaskStatus.todo,
    );

    await _tasksCollection.add(newTask.toMap());
  }

  /// Обновление задачи (редактирование текста)
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toMap());
  }

  /// Удаление задачи
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  /// Изменение статуса задачи.
  ///
  /// ВАЖНО: Эта версия НЕ начисляет баллы на клиенте!
  /// Баллы начисляются через Cloud Function (триггер на изменение документа).
  /// Пока Cloud Function не развернута — баллы НЕ начисляются автоматически.
  /// См. ниже заглушку для локальной разработки.
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final updateData = <String, dynamic>{
      'status': newStatus.name,
    };

    if (newStatus == TaskStatus.done) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    } else {
      updateData['completedAt'] = null;
    }

    await _tasksCollection.doc(taskId).update(updateData);
  }

  /// [ЗАГЛУШКА ДЛЯ ЛОКАЛЬНОЙ РАЗРАБОТКИ]
  /// Имитирует Cloud Function: начисляет баллы при завершении задачи.
  /// Использовать ТОЛЬКО пока Cloud Functions не развернуты.
  /// После развертывания Cloud Function — УДАЛИТЬ этот метод!
  Future<void> _devAwardStarsOnComplete(String taskId, TaskStatus newStatus) async {
    if (newStatus != TaskStatus.done) return;

    final taskDoc = await _tasksCollection.doc(taskId).get();
    if (!taskDoc.exists) return;

    final data = taskDoc.data()!;
    final childId = data['childId'] as String?;
    final rewardStars = (data['rewardStars'] as num?)?.toInt() ?? 0;

    if (childId != null && rewardStars > 0) {
      await _firestore.collection('users').doc(childId).update({
        'stars': FieldValue.increment(rewardStars),
      });
    }
  }
    /// Поток профиля ребенка (для отображения баланса звёзд в UI)
  /// Это просто ЧТЕНИЕ данных — допустимо на клиенте.
  Stream<UserProfile?> getChildProfileStream(String childId) {
    return _firestore.collection('users').doc(childId).snapshots().map((doc) {
      if (doc.exists) return UserProfile.fromFirestore(doc);
      return null;
    });
  }
}