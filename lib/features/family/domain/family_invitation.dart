import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationType {
  parentToChild, // Родитель приглашает ребенка
  childToParent, // Ребенок приглашает родителя
}

enum InvitationStatus {
  pending,    // Ожидает подтверждения
  accepted,   // Принято
  rejected,   // Отклонено
  cancelled,  // Отменено отправителем
}

class FamilyInvitation {
  final String id;
  final String fromUid;       // Кто отправил (UID)
  final String fromName;      // Имя отправителя
  final String toEmail;       // Email получателя
  final InvitationType type;  // Тип приглашения
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FamilyInvitation({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toEmail,
    required this.type,
    this.status = InvitationStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  factory FamilyInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyInvitation(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      fromName: data['fromName'] ?? 'Неизвестно',
      toEmail: data['toEmail'] ?? '',
      type: InvitationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => InvitationType.parentToChild,
      ),
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUid': fromUid,
      'fromName': fromName,
      'toEmail': toEmail,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  FamilyInvitation copyWith({
    String? id,
    String? fromUid,
    String? fromName,
    String? toEmail,
    InvitationType? type,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FamilyInvitation(
      id: id ?? this.id,
      fromUid: fromUid ?? this.fromUid,
      fromName: fromName ?? this.fromName,
      toEmail: toEmail ?? this.toEmail,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}