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

  String? get currentParentId => _auth.currentUser?.uid;

  CollectionReference get _childrenCollection => _firestore.collection('children');

  /// Поток списка детей для текущего родителя
  Stream<List<Child>> getChildrenStream() {
    final parentId = currentParentId;
    if (parentId == null) return Stream.value([]);

    return _childrenCollection
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Child.fromFirestore(doc))
              .toList();
        });
        // Убрали .handleError отсюда, чтобы не ломать тип Stream<List<Child>>.
        // Ошибки лучше обрабатывать в UI через .when(data, error, loading).
  }

  Future<void> addChild(Child child) async {
    if (currentParentId == null) throw Exception('Родитель не авторизован');
    await _childrenCollection.add(child.toMap());
  }

  Future<void> deleteChild(String childId) async {
    await _childrenCollection.doc(childId).delete();
  }
  
  Future<void> updateChild(Child child) async {
    await _childrenCollection.doc(child.id).update(child.toMap());
  }
}