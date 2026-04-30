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

  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _usersCollection => _firestore.collection('users');

  String? get currentUid => _auth.currentUser?.uid;

  /// Поток задач для конкретного ребенка
  Stream<List<Task>> getTasksForChildStream(String childId) {
    return _tasksCollection
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList());
  }

  /// Создание новой задачи
  Future<void> createTask(String childId, String title, String description, int rewardStars) async {
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

  /// Обновление задачи (редактирование текста, удаление)
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toMap());
  }

  /// Удаление задачи
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  /// Изменение статуса задачи с начислением наград
  /// Если статус меняется на 'done', начисляются звезды.
  /// Если статус меняется с 'done' на другой, звезды списываются (опционально, сейчас просто не начисляем повторно).
  Future<void> updateTaskStatus(Task task, TaskStatus newStatus) async {
    await _firestore.runTransaction((transaction) async {
      final taskRef = _tasksCollection.doc(task.id);
      
      // 1. Обновляем задачу
      final updateData = {
        'status': newStatus.name,
        if (newStatus == TaskStatus.done) 'completedAt': Timestamp.fromDate(DateTime.now()),
        if (newStatus != TaskStatus.done) 'completedAt': null,
      };
      
      transaction.update(taskRef, updateData);

      // 2. Если задача выполнена, начисляем звезды ребенку
      if (newStatus == TaskStatus.done && task.status != TaskStatus.done) {
        final userRef = _usersCollection.doc(task.childId);
        final userDoc = await transaction.get(userRef);
        
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          final currentStars = (data?['stars'] as int?) ?? 0;
          transaction.update(userRef, {
            'stars': currentStars + task.rewardStars,
          });
        }
      } 
      // 3. (Опционально) Если убрали статус "выполнено", можно списать звезды. 
      // Пока оставим без списания, чтобы не усложнять логику для MVP.
    });
  }
  
  /// Получение профиля ребенка (для проверки баланса и т.д.)
  Stream<UserProfile?> getChildProfileStream(String childId) {
    return _usersCollection.doc(childId).snapshots().map((doc) {
      if (doc.exists) return UserProfile.fromFirestore(doc);
      return null;
    });
  }
}