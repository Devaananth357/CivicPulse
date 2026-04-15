import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_service.dart';
import '../models/sos_alert.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  Future<void> triggerSOS(String userId) async {
    final String location = await _locationService.getCurrentLocation();

    await _firestore.collection('sos_alerts').add({
      'userId': userId,
      'status': 'active',
      'message': 'Emergency SOS triggered',
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
