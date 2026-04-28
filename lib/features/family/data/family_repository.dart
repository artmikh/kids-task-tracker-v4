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

    final senderDoc = await _usersCollection.doc(uid).get();
    if (!senderDoc.exists) throw Exception('Профиль отправителя не найден');
    final senderName = UserProfile.fromFirestore(senderDoc).displayName;

    if (targetEmail == currentEmail) {
      throw Exception('Нельзя отправить приглашение самому себе');
    }

    // Проверка на дубликаты активных приглашений
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

  /// Входящие приглашения
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

  /// Исходящие приглашения
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

    await _firestore.runTransaction((transaction) async {
      final inviteRef = _invitationsCollection.doc(invitationId);
      final inviteDoc = await transaction.get(inviteRef);

      if (!inviteDoc.exists) throw Exception('Приглашение не найдено');
      
      final invitation = FamilyInvitation.fromFirestore(inviteDoc);
      if (invitation.toEmail != email) throw Exception('Это приглашение не для вас');

      transaction.update(inviteRef, {
        'status': InvitationStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      final receiverQuery = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (receiverQuery.docs.isEmpty) throw Exception('Пользователь не найден');
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
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Получить список детей для текущего родителя
  Stream<List<UserProfile>> getMyChildrenStream() {
    final parentId = currentUid;
    // Если пользователь разлогинился, сразу возвращаем пустой поток
    if (parentId == null) return Stream.value([]);

    return _linksCollection
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return <UserProfile>[];

          final List<UserProfile> profiles = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            // Безопасное приведение типа
            if (data is Map<String, dynamic>) {
              final childId = data['childId'] as String?;
              if (childId != null) {
                final childDoc = await _usersCollection.doc(childId).get();
                if (childDoc.exists) {
                  final childData = childDoc.data();
                  if (childData is Map<String, dynamic>) {
                     // Опционально: проверяем роль, чтобы быть уверенными
                    if (childData['role'] == 'child') {
                      profiles.add(UserProfile.fromFirestore(childDoc));
                    } else {
                      // Если роль не совпадает, все равно добавляем, но можно логировать warning
                      profiles.add(UserProfile.fromFirestore(childDoc));
                    }
                  }
                }
              }
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
          if (snapshot.docs.isEmpty) return <UserProfile>[];

          final List<UserProfile> profiles = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data is Map<String, dynamic>) {
              final parentId = data['parentId'] as String?;
              if (parentId != null) {
                final parentDoc = await _usersCollection.doc(parentId).get();
                if (parentDoc.exists) {
                  final parentData = parentDoc.data();
                  if (parentData is Map<String, dynamic>) {
                    if (parentData['role'] == 'parent') {
                      profiles.add(UserProfile.fromFirestore(parentDoc));
                    } else {
                      profiles.add(UserProfile.fromFirestore(parentDoc));
                    }
                  }
                }
              }
            }
          }
          return profiles;
        });
  }
}