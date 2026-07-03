import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Broadcast {
  final String? id;
  final String message;
  final LatLng center;
  final double radius; // In meters
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? excludeUserId;
  final String? incidentId;
  final bool isActive;

  Broadcast({
    this.id,
    required this.message,
    required this.center,
    required this.radius,
    required this.createdAt,
    required this.expiresAt,
    this.excludeUserId,
    this.incidentId,
    this.isActive = true,
  });

  factory Broadcast.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final centerData = data['center'] as Map<String, dynamic>;
    
    return Broadcast(
      id: doc.id,
      message: data['message'] ?? '',
      center: LatLng(
        (centerData['lat'] as num).toDouble(),
        (centerData['lng'] as num).toDouble(),
      ),
      radius: (data['radius'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      excludeUserId: data['excludeUserId'] as String?,
      incidentId: data['incidentId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'center': {
        'lat': center.latitude,
        'lng': center.longitude,
      },
      'radius': radius,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'excludeUserId': excludeUserId,
      'incidentId': incidentId,
      'isActive': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
