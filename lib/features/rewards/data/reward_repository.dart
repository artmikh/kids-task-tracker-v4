import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/reward_model.dart';

class RewardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RewardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _rewardsCollection => _firestore.collection('rewards');

  String? get currentUid => _auth.currentUser?.uid;

  /// Поток списка наград для текущего родителя
  Stream<List<Reward>> getMyRewardsStream() {
    final parentId = currentUid;
    if (parentId == null) return Stream.value([]);

    return _rewardsCollection
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reward.fromFirestore(doc))
            .toList());
  }

  /// Создать награду
  Future<void> addReward(Reward reward) async {
    final parentId = currentUid;
    if (parentId == null) throw Exception('Родитель не авторизован');

    // ВАЖНО: Принудительно устанавливаем parentId перед сохранением
    final rewardWithParent = reward.copyWith(parentId: parentId);

    await _rewardsCollection.add(rewardWithParent.toMap());
  }

  /// Обновить награду (например, отметить подарок как выполненное или изменить цену)
  Future<void> updateReward(Reward reward) async {
    await _rewardsCollection.doc(reward.id).update(reward.toMap());
  }

  /// Удалить награду
  Future<void> deleteReward(String rewardId) async {
    await _rewardsCollection.doc(rewardId).delete();
  }
  
  /// Получить одну награду по ID
  Future<Reward?> getRewardById(String id) async {
    final doc = await _rewardsCollection.doc(id).get();
    if (doc.exists) return Reward.fromFirestore(doc);
    return null;
  }
}