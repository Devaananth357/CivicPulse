import 'package:cloud_firestore/cloud_firestore.dart';

class Verification {
  final String? id;
  final String incidentId;
  final String userId;
  final String response; // 'confirm' | 'deny'
  final DateTime createdAt;

  Verification({
    this.id,
    required this.incidentId,
    required this.userId,
    required this.response,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'userId': userId,
      'response': response,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Verification.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Verification(
      id: docId,
      incidentId: map['incidentId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      response: map['response'] as String? ?? 'confirm',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
