import 'package:cloud_firestore/cloud_firestore.dart';

class SystemStatus {
  final String status;
  final DateTime updatedAt;

  SystemStatus({
    required this.status,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SystemStatus.fromMap(Map<String, dynamic> map) {
    return SystemStatus(
      status: map['status'] as String? ?? 'Unknown',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
