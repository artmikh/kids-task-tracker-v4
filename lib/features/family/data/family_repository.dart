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

  /// Отправить приглашение
  Future<void> sendInvitation(String targetEmail, InvitationType type) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Пользователь не авторизован');

    // Получаем имя отправителя
    final senderDoc = await _usersCollection.doc(uid).get();
    if (!senderDoc.exists) throw Exception('Профиль отправителя не найден');
    final senderName = UserProfile.fromFirestore(senderDoc).displayName;

    // Проверка: не отправляем ли мы приглашение сами себе
    if (targetEmail == currentEmail) {
      throw Exception('Нельзя отправить приглашение самому себе');
    }

    // Проверка: существует ли уже активное приглашение
    final existingQuery = await _invitationsCollection
        .where('toEmail', isEqualTo: targetEmail)
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      throw Exception('Приглашение этому пользователю уже отправлено');
    }

    final invitation = FamilyInvitation(
      id: '', // ID сгенерируется Firestore
      fromUid: uid,
      fromName: senderName,
      toEmail: targetEmail,
      type: type,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
    );

    await _invitationsCollection.add(invitation.toMap());
  }

  /// Получить входящие приглашения для текущего пользователя
  Stream<List<FamilyInvitation>> getIncomingInvitationsStream() {
    final email = currentEmail;
    if (email == null) return Stream.value([]);

    return _invitationsCollection
        .where('toEmail', isEqualTo: email)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyInvitation.fromFirestore(doc))
            .toList());
  }

  /// Получить исходящие приглашения (для отображения статуса)
  Stream<List<FamilyInvitation>> getOutgoingInvitationsStream() {
    final uid = currentUid;
    if (uid == null) return Stream.value([]);

    return _invitationsCollection
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyInvitation.fromFirestore(doc))
            .toList());
  }

  /// Принять приглашение
  Future<void> acceptInvitation(String invitationId) async {
    final email = currentEmail;
    if (email == null) throw Exception('Пользователь не авторизован');

    // Транзакция для атомарности
    await _firestore.runTransaction((transaction) async {
      final inviteRef = _invitationsCollection.doc(invitationId);
      final inviteDoc = await transaction.get(inviteRef);

      if (!inviteDoc.exists) throw Exception('Приглашение не найдено');
      
      final invitation = FamilyInvitation.fromFirestore(inviteDoc);
      if (invitation.toEmail != email) throw Exception('Это приглашение не для вас');

      // Обновляем статус приглашения
      transaction.update(inviteRef, {
        'status': InvitationStatus.accepted.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Находим UID получателя (кто принял)
      final receiverQuery = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (receiverQuery.docs.isEmpty) throw Exception('Пользователь не найден');
      final receiverUid = receiverQuery.docs.first.id;

      // Создаем связь FamilyLink
      String parentId, childId;

      if (invitation.type == InvitationType.parentToChild) {
        parentId = invitation.fromUid;
        childId = receiverUid;
      } else {
        parentId = receiverUid; // В этом случае fromUid - это ребенок, а receiver - родитель
        childId = invitation.fromUid;
      }
      
      // Проверка на дубликат связи
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

  /// Отклонить приглашение
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

  /// Получить список детей для текущего родителя
  Stream<List<UserProfile>> getMyChildrenStream() {
    final parentId = currentUid;
    if (parentId == null) return Stream.value([]);

    // Сначала получаем связи
    return _linksCollection
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .asyncMap((snapshot) async {
          final childIds = snapshot.docs
              .map((doc) => FamilyLink.fromFirestore(doc).childId)
              .toList();
          
          if (childIds.isEmpty) return [];

          // Затем получаем профили детей
          // Примечание: Для большого количества детей лучше использовать batch-get или in-query
          final profiles = <UserProfile>[];
          for (var id in childIds) {
            final doc = await _usersCollection.doc(id).get();
            if (doc.exists) {
              profiles.add(UserProfile.fromFirestore(doc));
            }
          }
          return profiles;
        });
  }

  /// Получить список родителей для текущего ребенка
  Stream<List<UserProfile>> getMyParentsStream() {
    final childId = currentUid;
    if (childId == null) return Stream.value([]);

    return _linksCollection
        .where('childId', isEqualTo: childId)
        .snapshots()
        .asyncMap((snapshot) async {
          final parentIds = snapshot.docs
              .map((doc) => FamilyLink.fromFirestore(doc).parentId)
              .toList();
          
          if (parentIds.isEmpty) return [];

          final profiles = <UserProfile>[];
          for (var id in parentIds) {
            final doc = await _usersCollection.doc(id).get();
            if (doc.exists) {
              profiles.add(UserProfile.fromFirestore(doc));
            }
          }
          return profiles;
        });
  }
  
  /// Удалить связь (отвязать ребенка/родителя)
  Future<void> removeLink(String linkId) async {
    await _linksCollection.doc(linkId).delete();
  }
}