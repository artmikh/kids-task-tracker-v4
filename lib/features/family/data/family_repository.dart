import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/family_invitation.dart';
import '../domain/family_link.dart';
import '../../user/domain/user_profile.dart';

class FamilyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FamilyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _invitationsCollection => _firestore.collection('family_invitations');
  CollectionReference get _linksCollection => _firestore.collection('family_links');
  CollectionReference get _usersCollection => _firestore.collection('users');

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;

  // ... (метод sendInvitation и get...Stream без изменений, оставляем как было) ...
  
  Future<void> sendInvitation(String targetEmail, InvitationType type) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Пользователь не авторизован');

    final senderDoc = await _usersCollection.doc(uid).get();
    if (!senderDoc.exists) throw Exception('Профиль отправителя не найден');
    final senderName = UserProfile.fromFirestore(senderDoc).displayName;

    if (targetEmail == currentEmail) throw Exception('Нельзя отправить приглашение самому себе');

    final existingQuery = await _invitationsCollection
        .where('toEmail', isEqualTo: targetEmail)
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) throw Exception('Приглашение уже отправлено');

    final invitation = FamilyInvitation(
      id: '', 
      fromUid: uid,
      fromName: senderName,
      toEmail: targetEmail,
      type: type,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
    );

    await _invitationsCollection.add(invitation.toMap());
  }

  Stream<List<FamilyInvitation>> getIncomingInvitationsStream() {
    final email = currentEmail;
    if (email == null) return Stream.value([]);
    return _invitationsCollection
        .where('toEmail', isEqualTo: email)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FamilyInvitation.fromFirestore(doc)).toList());
  }

  Stream<List<FamilyInvitation>> getOutgoingInvitationsStream() {
    final uid = currentUid;
    if (uid == null) return Stream.value([]);
    return _invitationsCollection
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FamilyInvitation.fromFirestore(doc)).toList());
  }

  /// Получить список детей для текущего родителя
  Stream<List<UserProfile>> getMyChildrenStream() {
    final parentId = currentUid;
    if (parentId == null) return Stream.value([]);

    return _linksCollection
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .asyncMap((linksSnapshot) async {
          final childIds = linksSnapshot.docs
              .map((doc) => FamilyLink.fromFirestore(doc).childId)
              .toList();

          if (childIds.isEmpty) return [];

          // Ждем загрузки всех профилей
          final futures = childIds.map((id) => _usersCollection.doc(id).get()).toList();
          final docsSnapshot = await Future.wait(futures);

          return docsSnapshot
              .where((doc) => doc.exists)
              .map((doc) => UserProfile.fromFirestore(doc))
              .toList();
        });
  }

/// Получить список родителей для текущего ребенка
  Stream<List<UserProfile>> getMyParentsStream() {
    final childId = currentUid;
    if (childId == null) return Stream.value([]);

    return _linksCollection
        .where('childId', isEqualTo: childId)
        .snapshots()
        .asyncMap((linksSnapshot) async {
          final parentIds = linksSnapshot.docs
              .map((doc) => FamilyLink.fromFirestore(doc).parentId)
              .toList();

          if (parentIds.isEmpty) return [];

          final futures = parentIds.map((id) => _usersCollection.doc(id).get()).toList();
          final docsSnapshot = await Future.wait(futures);

          return docsSnapshot
              .where((doc) => doc.exists)
              .map((doc) => UserProfile.fromFirestore(doc))
              .toList();
        });
  }

  // Stream<List<UserProfile>> getMyParentsStream() {
  //   final childId = currentUid;
  //   if (childId == null) return Stream.value([]);
  //   return _linksCollection.where('childId', isEqualTo: childId).snapshots().asyncMap((snapshot) async {
  //     final parentIds = snapshot.docs.map((doc) => FamilyLink.fromFirestore(doc).parentId).toList();
  //     if (parentIds.isEmpty) return [];
  //     final profiles = <UserProfile>[];
  //     for (var id in parentIds) {
  //       final doc = await _usersCollection.doc(id).get();
  //       if (doc.exists) profiles.add(UserProfile.fromFirestore(doc));
  //     }
  //     return profiles;
  //   });
  // }

  /// ИСПРАВЛЕНО: Логика принятия приглашения
  Future<void> acceptInvitation(String invitationId) async {
    final email = currentEmail;
    if (email == null) throw Exception('Пользователь не авторизован');

    await _firestore.runTransaction((transaction) async {
      final inviteRef = _invitationsCollection.doc(invitationId);
      final inviteDoc = await transaction.get(inviteRef);

      if (!inviteDoc.exists) throw Exception('Приглашение не найдено');
      
      final invitation = FamilyInvitation.fromFirestore(inviteDoc);
      if (invitation.toEmail != email) throw Exception('Это приглашение не для вас');

      // Обновляем статус
      transaction.update(inviteRef, {
        'status': InvitationStatus.accepted.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Находим UID принявшего (получателя)
      final receiverQuery = await _usersCollection.where('email', isEqualTo: email).limit(1).get();
      if (receiverQuery.docs.isEmpty) throw Exception('Пользователь не найден');
      final receiverUid = receiverQuery.docs.first.id;
      final receiverProfile = UserProfile.fromFirestore(receiverQuery.docs.first);

      String? parentId;
      String? childId;

      // ОПРЕДЕЛЯЕМ РОЛИ ПРАВИЛЬНО
      if (invitation.type == InvitationType.parentToChild) {
        // Отправитель - родитель, Получатель - ребенок
        parentId = invitation.fromUid;
        childId = receiverUid;
        
        // Дополнительная проверка: действительно ли получатель ребенок?
        if (receiverProfile.role != UserRole.child) {
           // Можно выбросить ошибку или просто проигнорировать, но лучше предупредить
           print('Warning: User accepting parent-to-child invite is not a child role');
        }
      } else if (invitation.type == InvitationType.childToParent) {
        // Отправитель - ребенок, Получатель - родитель
        childId = invitation.fromUid;
        parentId = receiverUid;
        
        if (receiverProfile.role != UserRole.parent) {
           print('Warning: User accepting child-to-parent invite is not a parent role');
        }
      }

      if (parentId == null || childId == null) {
        throw Exception('Не удалось определить роли для связи');
      }

      // Проверка дубликата
      final existingLink = await _linksCollection
          .where('parentId', isEqualTo: parentId)
          .where('childId', isEqualTo: childId)
          .limit(1)
          .get();

      if (existingLink.docs.isEmpty) {
        final newLink = FamilyLink(
          id: '', 
          parentId: parentId, 
          childId: childId, 
          createdAt: DateTime.now()
        );
        transaction.set(_linksCollection.doc(), newLink.toMap());
      }
    });
  }

  Future<void> rejectInvitation(String invitationId) async {
    final email = currentEmail;
    if (email == null) throw Exception('Пользователь не авторизован');
    final inviteDoc = await _invitationsCollection.doc(invitationId).get();
    if (!inviteDoc.exists) return;
    final invitation = FamilyInvitation.fromFirestore(inviteDoc);
    if (invitation.toEmail != email) throw Exception('Это приглашение не для вас');
    await _invitationsCollection.doc(invitationId).update({
      'status': InvitationStatus.rejected.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
  
  Future<void> removeLink(String linkId) async {
    await _linksCollection.doc(linkId).delete();
  }
}