import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../user/domain/user_profile.dart';

class FamilyInvitation {
  final String id;
  final String fromUid;
  final String fromName;
  final String toEmail;
  final String type; // 'parent_to_child' или 'child_to_parent'
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  FamilyInvitation({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toEmail,
    required this.type,
    this.status = 'pending',
    required this.createdAt,
  });

  factory FamilyInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyInvitation(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      fromName: data['fromName'] ?? '',
      toEmail: data['toEmail'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'fromUid': fromUid,
      'fromName': fromName,
      'toEmail': toEmail,
      'type': type,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class FamilyLink {
  final String parentId;
  final String childId;
  final DateTime linkedAt;

  FamilyLink({required this.parentId, required this.childId, required this.linkedAt});

  factory FamilyLink.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyLink(
      parentId: data['parentId'] ?? '',
      childId: data['childId'] ?? '',
      linkedAt: (data['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FamilyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FamilyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // --- Приглашения ---

  /// Отправить приглашение
  Future<void> sendInvitation({
    required String toEmail,
    required String type, // 'parent_to_child'
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Не авторизован');

    // Получаем имя отправителя
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userName = userDoc.exists ? (userDoc.data()!['displayName'] as String) : 'Пользователь';

    // Проверка: не отправляли ли уже
    // (упрощено, в проде нужен запрос на существующие pending приглашения)

    await _firestore.collection('family_invitations').add({
      'fromUid': uid,
      'fromName': userName,
      'toEmail': toEmail.toLowerCase().trim(),
      'type': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Получить входящие приглашения для текущего пользователя (по email)
  Stream<List<FamilyInvitation>> getIncomingInvitationsStream() {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return Stream.value([]);

    return _firestore
        .collection('family_invitations')
        .where('toEmail', isEqualTo: user.email!.toLowerCase().trim())
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyInvitation.fromFirestore(doc))
            .toList());
  }

  /// Принять приглашение
  Future<void> acceptInvitation(String invitationId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Не авторизован');

    final inviteDoc = await _firestore.collection('family_invitations').doc(invitationId).get();
    if (!inviteDoc.exists) throw Exception('Приглашение не найдено');
    
    final invite = FamilyInvitation.fromFirestore(inviteDoc);

    // Транзакция: создать связь и обновить статус приглашения
    await _firestore.runTransaction((transaction) async {
      // 1. Создаем связь
      String parentId, childId;
      if (invite.type == 'parent_to_child') {
        parentId = invite.fromUid;
        childId = user.uid;
      } else {
        // child_to_parent (если реализуем)
        parentId = user.uid;
        childId = invite.fromUid; 
      }

      // Проверка на дубликат связи
      final existingLink = await _firestore
          .collection('family_links')
          .where('parentId', isEqualTo: parentId)
          .where('childId', isEqualTo: childId)
          .limit(1)
          .get();
      
      if (existingLink.docs.isEmpty) {
        transaction.set(_firestore.collection('family_links').document(), {
          'parentId': parentId,
          'childId': childId,
          'linkedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Обновляем статус приглашения
      transaction.update(inviteDoc.reference, {'status': 'accepted'});
    });
  }

  /// Отклонить приглашение
  Future<void> rejectInvitation(String invitationId) async {
    await _firestore.collection('family_invitations').doc(invitationId).update({'status': 'rejected'});
  }

  // --- Связи ---

  /// Получить всех детей для текущего родителя
  Stream<List<FamilyLink>> getMyChildrenLinksStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('family_links')
        .where('parentId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyLink.fromFirestore(doc))
            .toList());
  }
  
  /// Получить всех родителей для текущего ребенка
  Stream<List<FamilyLink>> getMyParentsLinksStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('family_links')
        .where('childId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyLink.fromFirestore(doc))
            .toList());
  }
}