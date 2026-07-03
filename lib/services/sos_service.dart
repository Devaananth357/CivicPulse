import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_service.dart';
import '../models/sos_alert.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  Future<void> triggerSOS(String userId) async {
    final String location = await _locationService.getCurrentLocation();
    
    // Attempt to extract lat/lng for mapping
    double? latitude;
    double? longitude;
    try {
      final parts = location.split(',');
      if (parts.length >= 2) {
        latitude = double.tryParse(parts[0].trim());
        longitude = double.tryParse(parts[1].trim());
      }
    } catch (e) {
      print("Error parsing location for SOS: $e");
    }

    final batch = _firestore.batch();
    
    // 1. Create traditional SOS alert for backwards compatibility
    final sosRef = _firestore.collection('sos_alerts').doc();
    final incidentRef = _firestore.collection('incidents').doc(); // Unified ID strategy

    batch.set(sosRef, {
      'userId': userId,
      'status': 'active',
      'message': 'Emergency SOS triggered',
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'incidentId': incidentRef.id, // Linking back to main incident
    });

    // 2. Create Incident entry for Admin Dashboard integration
    batch.set(incidentRef, {
      'type': 'SOS',
      'description': 'EMERGENCY SOS SIGNAL DETECTED',
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'Open',
      'isSos': true,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'aiConfidence': 100.0, // High priority
      'aiPriority': 'CRITICAL',
      'aiReasoning': 'SOS signal manually triggered by user.',
      'backupRequests': [],
      'legacySosId': sosRef.id, // Double-link for redundancy
    });

    // 3. Update Global System Status to Danger
    batch.set(_firestore.collection('system_status').doc('current'), {
      'status': 'Danger',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 4. Update individual user status to Danger
    batch.update(_firestore.collection('users').doc(userId), {
      'status': 'danger',
      'isInDanger': true,
      'lastActive': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<SosAlert>> getSosAlerts() {
    return _firestore
        .collection('sos_alerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return SosAlert.fromMap(data, doc.id);
            }).toList());
  }
}
