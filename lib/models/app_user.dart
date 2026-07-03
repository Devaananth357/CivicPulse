import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final String role; // 'admin', 'responder', 'user'
  final String status; // 'safe', 'danger'
  final bool isInDanger;
  final DateTime lastActive;
  final DateTime? lastSafeAt;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.role = 'user',
    this.status = 'safe',
    this.isInDanger = false,
    required this.lastActive,
    this.lastSafeAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role,
      'status': status,
      'isInDanger': isInDanger,
      'lastActive': Timestamp.fromDate(lastActive),
      'lastSafeAt': lastSafeAt != null ? Timestamp.fromDate(lastSafeAt!) : null,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String? ?? 'user',
      status: map['status'] as String? ?? 'safe',
      isInDanger: map['isInDanger'] as bool? ?? false,
      lastActive: (map['lastActive'] as Timestamp).toDate(),
      lastSafeAt: (map['lastSafeAt'] as Timestamp?)?.toDate(),
    );
  }
}
