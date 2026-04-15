import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class SosAlert {
  final String id;
  final String userId;
  final String message;
  final String location;
  final String status;
  final DateTime createdAt;

  SosAlert({
    required this.id,
    required this.userId,
    required this.message,
    required this.location,
    required this.status,
    required this.createdAt,
  });

  LatLng? get latLng {
    try {
      // Robust extraction using RegEx to find numbers (handles "lat:12.3, lng:45.6" etc.)
      // Matches floating point numbers like 12.3, -45.0, .5, etc.
      final numberRegex = RegExp(r'[-+]?\d*\.?\d+');
      final matches = numberRegex.allMatches(location).toList();
      
      if (matches.length >= 2) {
        final lat = double.tryParse(matches[0].group(0) ?? '');
        final lng = double.tryParse(matches[1].group(0) ?? '');
        
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      print("Error parsing location for alert $id: $e");
    }
    return null;
  }

  factory SosAlert.fromMap(Map<String, dynamic> map, String docId) {
    // Safely handle 'location' if it's a Map
    String displayLocation = 'Unknown Location';
    final rawLocation = map['location'];
    if (rawLocation is String) {
      displayLocation = rawLocation;
    } else if (rawLocation is Map) {
      final lat = rawLocation['lat'];
      final lng = rawLocation['lng'];
      if (lat != null && lng != null) {
        displayLocation = "Lat: ${lat.toStringAsFixed(2)}, Lng: ${lng.toStringAsFixed(2)}";
      }
    }

    return SosAlert(
      id: docId,
      userId: map['userId'] as String? ?? 'unknown',
      message: map['message'] as String? ?? 'Emergency SOS triggered',
      location: displayLocation,
      status: map['status'] as String? ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'location': location,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
