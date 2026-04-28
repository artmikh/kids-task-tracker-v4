import 'package:cloud_firestore/cloud_firestore.dart';

/// Подтвержденная связь между родителем и ребенком
class FamilyLink {
  final String id;
  final String parentId;
  final String childId;
  final DateTime createdAt;

  FamilyLink({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.createdAt,
  });

  factory FamilyLink.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyLink(
      id: doc.id,
      parentId: data['parentId'] ?? '',
      childId: data['childId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childId': childId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}