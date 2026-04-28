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
  
  // Нормализуем email: нижний регистр + trim
  String? get currentEmail {
    final email = _auth.currentUser?.email;
    return email?.trim().toLowerCase();
  }

    /// Отправить приглашение
  Future<void> sendInvitation(String targetEmail, InvitationType type) async {
    final uid = currentUid;
    final myEmail = currentEmail;
    
    if (uid == null || myEmail == null) throw Exception('Пользователь не авторизован');

    // 1. Нормализация email
    final normalizedTargetEmail = targetEmail.trim().toLowerCase();
    final normalizedMyEmail = myEmail.toLowerCase();

    if (normalizedTargetEmail == normalizedMyEmail) {
      throw Exception('Нельзя отправить приглашение самому себе');
    }

    // 2. Находим профиль получателя, чтобы проверить его роль
    final targetUserQuery = await _usersCollection
        .where('email', isEqualTo: normalizedTargetEmail)
        .limit(1)
        .get();

    if (targetUserQuery.docs.isEmpty) {
      throw Exception('Пользователь с таким email не найден. Попросите его зарегистрироваться.');
    }

    final targetUserProfile = UserProfile.fromFirestore(targetUserQuery.docs.first);
    final targetUid = targetUserProfile.uid;
    final targetRole = targetUserProfile.role;

    // 3. Проверка ролей (Родитель <-> Ребенок)
    if (type == InvitationType.parentToChild && targetRole != UserRole.child) {
      throw Exception('Ошибка: Вы пытаетесь пригласить ребенка, но этот пользователь зарегистрирован как Родитель.');
    }
    if (type == InvitationType.childToParent && targetRole != UserRole.parent) {
      throw Exception('Ошибка: Вы пытаетесь пригласить родителя, но этот пользователь зарегистрирован как Ребенок.');
    }

    // 4. Проверка: нет ли уже активной связи
    bool hasLink = false;
    if (type == InvitationType.parentToChild) {
      hasLink = await _checkExistingLink(uid, targetUid);
    } else {
      hasLink = await _checkExistingLink(targetUid, uid);
    }

    if (hasLink) {
      throw Exception('Этот пользователь уже добавлен в вашу семью.');
    }

    // 5. Проверка: нет ли уже ожидающего приглашения
    final hasPending = await _checkPendingInvitation(uid, normalizedTargetEmail, type);
    if (hasPending) {
      throw Exception('Приглашение этому пользователю уже отправлено и ожидает ответа.');
    }

    // Получаем имя отправителя
    final senderDoc = await _usersCollection.doc(uid).get();
    if (!senderDoc.exists) throw Exception('Профиль отправителя не найден');
    final senderName = UserProfile.fromFirestore(senderDoc).displayName;

    // Создаем приглашение
    final invitation = FamilyInvitation(
      id: '',
      fromUid: uid,
      fromName: senderName,
      toEmail: normalizedTargetEmail, // Сохраняем нормализованный email
      type: type,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
    );

    await _invitationsCollection.add(invitation.toMap());
  }

  /// Проверка наличия активной связи между родителем и ребенком
  Future<bool> _checkExistingLink(String parentId, String childId) async {
    final query = await _linksCollection
        .where('parentId', isEqualTo: parentId)
        .where('childId', isEqualTo: childId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Проверка наличия ожидающего приглашения
  Future<bool> _checkPendingInvitation(String fromUid, String toEmail, InvitationType type) async {
    final query = await _invitationsCollection
        .where('fromUid', isEqualTo: fromUid)
        .where('toEmail', isEqualTo: toEmail)
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Входящие приглашения (УНИВЕРСАЛЬНО: где toEmail == мой email)
  Stream<List<FamilyInvitation>> getIncomingInvitationsStream() {
    final email = currentEmail;
    if (email == null) {
      print('[REPO] Email null, возвращаем пустой стрим входящих');
      return Stream.value([]);
    }

    print('[REPO] Подписка на входящие для: $email');
    
    return _invitationsCollection
        .where('toEmail', isEqualTo: email)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final invites = snapshot.docs
              .map((doc) => FamilyInvitation.fromFirestore(doc))
              .toList();
          print('[REPO] Получено входящих приглашений: ${invites.length}');
          return invites;
        });
  }

  /// Исходящие приглашения (УНИВЕРСАЛЬНО: где fromUid == мой uid)
  Stream<List<FamilyInvitation>> getOutgoingInvitationsStream() {
    final uid = currentUid;
    if (uid == null) {
      print('[REPO] UID null, возвращаем пустой стрим исходящих');
      return Stream.value([]);
    }

    print('[REPO] Подписка на исходящие для: $uid');

    return _invitationsCollection
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final invites = snapshot.docs
              .map((doc) => FamilyInvitation.fromFirestore(doc))
              .toList();
          print('[REPO] Получено исходящих приглашений: ${invites.length}');
          return invites;
        });
  }

  /// Принять приглашение
  Future<void> acceptInvitation(String invitationId) async {
    final email = currentEmail;
    if (email == null) throw Exception('Пользователь не авторизован');

    await _firestore.runTransaction((transaction) async {
      final inviteRef = _invitationsCollection.doc(invitationId);
      final inviteDoc = await transaction.get(inviteRef);

      if (!inviteDoc.exists) throw Exception('Приглашение не найдено');

      final invitation = FamilyInvitation.fromFirestore(inviteDoc);
      
      // Сравнение нормализованных email
      if (invitation.toEmail != email) {
        throw Exception('Это приглашение не для вас (${invitation.toEmail} != $email)');
      }

      transaction.update(inviteRef, {
        'status': InvitationStatus.accepted.name,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      final receiverQuery = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) throw Exception('Профиль пользователя не найден');
      final receiverUid = receiverQuery.docs.first.id;

      String parentId, childId;

      if (invitation.type == InvitationType.parentToChild) {
        parentId = invitation.fromUid;
        childId = receiverUid;
      } else {
        parentId = receiverUid;
        childId = invitation.fromUid;
      }

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
          createdAt: DateTime.now(),
        );
        transaction.set(_linksCollection.doc(), newLink.toMap());
        print('[REPO] Связь создана: $parentId <-> $childId');
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
    if (invitation.toEmail != email) throw Exception('Приглашение не для вас');

    await _invitationsCollection.doc(invitationId).update({
      'status': InvitationStatus.rejected.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Список детей для родителя
  Stream<List<UserProfile>> getMyChildrenStream() {
    final parentId = currentUid;
    if (parentId == null) return Stream.value([]);

    return _linksCollection
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .asyncMap((snapshot) async {
          final childIds = snapshot.docs.map((doc) => FamilyLink.fromFirestore(doc).childId).toList();
          if (childIds.isEmpty) return [];

          final profiles = <UserProfile>[];
          for (var id in childIds) {
            final doc = await _usersCollection.doc(id).get();
            if (doc.exists) profiles.add(UserProfile.fromFirestore(doc));
          }
          return profiles;
        });
  }

  /// Список родителей для ребенка
  Stream<List<UserProfile>> getMyParentsStream() {
    final childId = currentUid;
    if (childId == null) return Stream.value([]);

    return _linksCollection
        .where('childId', isEqualTo: childId)
        .snapshots()
        .asyncMap((snapshot) async {
          final parentIds = snapshot.docs.map((doc) => FamilyLink.fromFirestore(doc).parentId).toList();
          if (parentIds.isEmpty) return [];

          final profiles = <UserProfile>[];
          for (var id in parentIds) {
            final doc = await _usersCollection.doc(id).get();
            if (doc.exists) profiles.add(UserProfile.fromFirestore(doc));
          }
          return profiles;
        });
  }
}