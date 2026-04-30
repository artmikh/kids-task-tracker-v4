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
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final taskRef = _tasksCollection.doc(taskId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Читаем текущее состояние задачи ВНУТРИ транзакции
        final taskDoc = await transaction.get(taskRef);
        
        if (!taskDoc.exists) {
          throw Exception('Задача не найдена');
        }

        final data = taskDoc.data() as Map<String, dynamic>;
        final currentStatusStr = data['status'] as String;
        
        // Если статус уже такой же, ничего не делаем (чтобы не начислять звезды повторно при клике)
        if (currentStatusStr == newStatus.name) {
          print('⚠️ Статус уже установлен в $newStatus, пропускаем.');
          return; 
        }

        // 2. Формируем данные для обновления задачи
        final updateData = <String, dynamic>{
          'status': newStatus.name,
        };

        if (newStatus == TaskStatus.done) {
          updateData['completedAt'] = FieldValue.serverTimestamp();
        } else {
          updateData['completedAt'] = null;
        }

        // Обновляем задачу
        transaction.update(taskRef, updateData);
        print('✅ Задача $taskId обновлена: статус -> ${newStatus.name}');

        // 3. Логика начисления звезд (ТОЛЬКО если переходим в DONE)
        if (newStatus == TaskStatus.done) {
          final childId = data['childId'] as String?;
          final rewardStars = (data['rewardStars'] as num?)?.toInt() ?? 0;

          if (childId != null && rewardStars > 0) {
            final userRef = _usersCollection.doc(childId);
            
            // Используем FieldValue.increment для безопасного увеличения числа
            // Это исключает гонки данных и проблемы с приведением типов
            transaction.update(userRef, {
              'stars': FieldValue.increment(rewardStars),
            });
            
            print('💰 Начислено $rewardStars звезд ребенку $childId');
          } else {
            print('⚠️ Пропуск начисления звезд: childId=$childId, rewardStars=$rewardStars');
          }
        }
      });
      
      print('🎉 Транзакция успешно завершена!');
      
    } catch (e, stackTrace) {
      print('❌ Критическая ошибка в транзакции: $e');
      print('Стек ошибки: $stackTrace');
      rethrow; // Пробрасываем ошибку дальше, чтобы UI мог её показать
    }
  }
  
  /// Получение профиля ребенка (для проверки баланса и т.д.)
  Stream<UserProfile?> getChildProfileStream(String childId) {
    return _usersCollection.doc(childId).snapshots().map((doc) {
      if (doc.exists) return UserProfile.fromFirestore(doc);
      return null;
    });
  }
}