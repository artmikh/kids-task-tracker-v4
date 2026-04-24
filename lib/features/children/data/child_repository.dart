import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/child_model.dart';

class ChildRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChildRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Получаем текущего авторизованного родителя
  String? get currentParentId => _auth.currentUser?.uid;

  // Коллекция детей
  CollectionReference get _childrenCollection => _firestore.collection('children');

  /// Поток списка детей для текущего родителя
  Stream<List<Child>> getChildrenStream() {
    final parentId = currentParentId;
    if (parentId == null) return Stream.value([]);

    return _childrenCollection
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Child.fromFirestore(doc))
            .toList());
  }

  /// Добавление нового ребенка
  Future<void> addChild(Child child) async {
    if (currentParentId == null) throw Exception('Родитель не авторизован');
    
    // Мы не передаем ID, он сгенерируется автоматически при добавлении
    final docRef = await _childrenCollection.add(child.toMap());
    // Опционально можно обновить документ с правильным ID, если нужно, 
    // но обычно хватает того, что мы храним ID внутри toMap или используем doc.id
  }

  /// Удаление ребенка
  Future<void> deleteChild(String childId) async {
    await _childrenCollection.doc(childId).delete();
  }
  
  /// Обновление данных ребенка
  Future<void> updateChild(Child child) async {
    await _childrenCollection.doc(child.id).update(child.toMap());
  }
}