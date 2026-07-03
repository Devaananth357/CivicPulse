import 'package:cloud_firestore/cloud_firestore.dart';

class Responder {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String imageUrl;
  final String specialization;
  final String availability; // "available", "busy"
  final String? assignedIncidentId;
  final double latitude;
  final double longitude;
  final String role;
  final int missionsCompleted;
  final double rating;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  Responder({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.specialization,
    this.availability = 'available',
    this.assignedIncidentId,
    required this.latitude,
    required this.longitude,
    this.role = 'responder',
    this.missionsCompleted = 0,
    this.rating = 5.0,
    this.createdAt,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'specialization': specialization,
      'availability': availability,
      'assignedIncidentId': assignedIncidentId,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'latitude': latitude,
      'longitude': longitude,
      'role': role,
      'missionsCompleted': missionsCompleted,
      'rating': rating,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : FieldValue.serverTimestamp(),
    };
  }

  factory Responder.fromMap(Map<String, dynamic> map, String docId) {
    // Prioritize top-level latitude/longitude, fall back to location object
    final double lat = (map['latitude'] as num?)?.toDouble() ?? 
                       (map['location']?['lat'] as num?)?.toDouble() ?? 0.0;
    final double lng = (map['longitude'] as num?)?.toDouble() ?? 
                       (map['location']?['lng'] as num?)?.toDouble() ?? 0.0;
    
    return Responder(
      id: docId,
      name: map['name'] as String? ?? 'Unknown Agent',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      specialization: map['specialization'] as String? ?? 'general',
      availability: map['availability'] as String? ?? 'available',
      assignedIncidentId: map['assignedIncidentId'] as String?,
      latitude: lat,
      longitude: lng,
      role: map['role'] as String? ?? 'responder',
      missionsCompleted: (map['missionsCompleted'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}
