import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/system_status.dart';
import '../models/incident.dart';
import '../models/sos_alert.dart';
import '../models/responder.dart';
import '../models/chat_message.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Fetch system status as a STREAM from: collection: system_status, document: current
  Stream<SystemStatus> getSystemStatusStream() {
    return _firestore
        .collection('system_status')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return SystemStatus.fromMap(doc.data()!);
      }
      return SystemStatus(status: 'Normal', updatedAt: DateTime.now());
    }).handleError((e) {
      print("FirestoreService - getSystemStatusStream Error: $e");
      return SystemStatus(status: 'Offline', updatedAt: DateTime.now());
    });
  }

  // 1a (DEPRECATED). Fetch system status once (Future)
  Future<SystemStatus> getSystemStatus() async {
    try {
      final doc = await _firestore.collection('system_status').doc('current').get();
      if (doc.exists) {
        return SystemStatus.fromMap(doc.data()!);
      }
      return SystemStatus(status: 'Normal', updatedAt: DateTime.now());
    } catch (e) {
      print("FirestoreService - getSystemStatus Error: $e");
      return SystemStatus(status: 'Offline', updatedAt: DateTime.now());
    }
  }

  // 2. Fetch incidents for a specific user (Personalized Feed) - In-memory filtered to avoid Index errors
  Stream<Incident?> getLatestIncidentForUser(String userId) {
    return _firestore
        .collection('incidents')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final docs = snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .where((inc) => inc.status.toLowerCase() != 'completed')
          .toList();

      if (docs.isEmpty) return null;

      // Sort by createdAt descending
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs.first;
    }).handleError((e) {
      print("FirestoreService - getLatestIncidentForUser Error: $e");
      return null;
    });
  }

  // 2a. Fetch incidents global (Backwards compatibility/Admin) - In-memory filtered to avoid Index errors
  Stream<Incident?> getLatestIncident() {
    return _firestore
        .collection('incidents')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final docs = snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .where((inc) => inc.status.toLowerCase() != 'completed')
          .toList();

      if (docs.isEmpty) return null;

      // Sort by status then createdAt descending
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs.first;
    }).handleError((e) {
      print("FirestoreService - getLatestIncident Error: $e");
      return null;
    });
  }

  // 3. Fetch responders count: collection: responders, where availability == "available"
  Future<int> getAvailableRespondersCount() async {
    try {
      final snapshot = await _firestore
          .collection('responders')
          .where('availability', isEqualTo: 'available')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("FirestoreService - getAvailableRespondersCount Error: $e");
      return 0;
    }
  }

  // 4. Fetch SOS alerts from: collection: sos_alerts, order by: createdAt (descending)
  Stream<List<SosAlert>> getSosAlertsStream() {
    return _firestore
        .collection('sos_alerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SosAlert.fromMap(doc.data(), doc.id);
      }).toList();
    }).handleError((e) {
      print("FirestoreService - getSosAlertsStream Error: $e");
      return <SosAlert>[];
    });
  }

  // 5. [Duplicate removed - see standardized version at bottom]


  // 6. Fetch ACTIVE incidents as a stream (filters out completed)
  Stream<List<Incident>> getIncidentsStream() {
    return _firestore
        .collection('incidents')
        .where('status', whereNotIn: ['completed'])
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Incident.fromMap(doc.data(), doc.id)).toList();
    }).handleError((e) {
      print("FirestoreService - getIncidentsStream Error: $e");
      return <Incident>[];
    });
  }

  // 7. Get single responder stream (for live tracking)
  Stream<Responder?> getResponderStream(String responderId) {
    return _firestore
        .collection('responders')
        .doc(responderId)
        .snapshots()
        .map((doc) => doc.exists ? Responder.fromMap(doc.data()!, doc.id) : null)
        .handleError((e) {
      print("FirestoreService - getResponderStream Error: $e");
      return null;
    });
  }

  // 6a. Fetch COMPLETED incidents as a stream
  Stream<List<Incident>> getCompletedIncidentsStream() {
    return _firestore
        .collection('incidents')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Incident.fromMap(doc.data(), doc.id)).toList();
      // Sort by createdAt descending (or completedAt if we want to be more specific)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((e) {
      print("FirestoreService - getCompletedIncidentsStream Error: $e");
      return <Incident>[];
    });
  }

  // 7. Fetch ALL responders as a stream
  Stream<List<Responder>> getRespondersStream() {
    return _firestore
        .collection('responders')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Responder.fromMap(doc.data(), doc.id)).toList();
    }).handleError((e) {
      print("FirestoreService - getRespondersStream Error: $e");
      return <Responder>[];
    });
  }
  // 8. Add a new responder to Firestore
  Future<void> addResponder(Responder responder) async {
    try {
      await _firestore
          .collection('responders')
          .doc(responder.id)
          .set(responder.toMap());
    } catch (e) {
      print("FirestoreService - addResponder Error: $e");
      throw Exception('Failed to add responder: $e');
    }
  }

  // 10. Stream for a specific incident's metadata
  Stream<Incident?> getIncidentStream(String incidentId) {
    return _firestore
        .collection('incidents')
        .doc(incidentId)
        .snapshots()
        .map((doc) => doc.exists ? Incident.fromMap(doc.data()!, doc.id) : null);
  }

  // 11. Accept Mission
  Future<void> acceptMission(String responderId, String incidentId) async {
    final batch = _firestore.batch();
    
    // Update incident status
    batch.update(_firestore.collection('incidents').doc(incidentId), {
      'status': 'in_progress',
    });
    
    // Update responder availability
    batch.update(_firestore.collection('responders').doc(responderId), {
      'availability': 'busy',
    });
    
    await batch.commit();
  }

  // 12. Reject Mission (Single Responder Opt-out)
  Future<void> rejectMission(String responderId, String incidentId) async {
    final batch = _firestore.batch();
    
    // Remove specific responder from incident's active list
    batch.update(_firestore.collection('incidents').doc(incidentId), {
      'assignedResponderIds': FieldValue.arrayRemove([responderId]),
      // We keep the details in responderDetails for history, but remove from active list
    });
    
    // Clear incident from responder and reset availability
    batch.update(_firestore.collection('responders').doc(responderId), {
      'assignedIncidentId': null,
      'availability': 'available',
    });
    
    await batch.commit();
  }

  // 13. Assign Responder to Incident (Supports Multiple Assign)
  Future<void> assignResponderToIncident(String responderId, String incidentId) async {
    // 1. Fetch responder data first to cache in incident
    final responderDoc = await _firestore.collection('responders').doc(responderId).get();
    if (!responderDoc.exists) throw Exception('Responder not found');
    
    final responderData = responderDoc.data()!;
    final Map<String, dynamic> details = {
      'name': responderData['name'] ?? 'Responder Agent',
      'imageUrl': responderData['imageUrl'] ?? '',
      'specialization': responderData['specialization'] ?? 'General',
      'phone': responderData['phone'] ?? '',
    };

    final batch = _firestore.batch();
    
    // 2. Update incident with NEW responder details and ID
    batch.update(_firestore.collection('incidents').doc(incidentId), {
      'assignedResponderIds': FieldValue.arrayUnion([responderId]),
      'status': 'assigned',
      'responderDetails.$responderId': details, // Multi-responder details using dot notation
      // Backward compatibility for existing UI
      'assignedResponderId': responderId,
    });
    
    // 3. Update responder status
    batch.update(_firestore.collection('responders').doc(responderId), {
      'assignedIncidentId': incidentId,
      'availability': 'busy',
    });
    
    await batch.commit();
  }

  // 14. Update Responder Location (Dual-Sync for Compatibility)
  Future<void> updateResponderLocation(String responderId, double latitude, double longitude) async {
    try {
      await _firestore.collection('responders').doc(responderId).update({
        'latitude': latitude,
        'longitude': longitude,
        'location': {
          'lat': latitude,
          'lng': longitude,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("FirestoreService - updateResponderLocation Error: $e");
    }
  }

  // 15. Standardized Emergency Report with Top-Level Coordinates
  Future<void> submitEmergencyReport(Map<String, dynamic> reportData) async {
    try {
      // Ensure top-level lat/lng exist for dispatcher sorting
      final Map<String, dynamic> locationData = reportData['location'] ?? {};
      final double lat = (locationData['lat'] as num?)?.toDouble() ?? 0.0;
      final double lng = (locationData['lng'] as num?)?.toDouble() ?? 0.0;

      await _firestore.collection('incidents').add({
        ...reportData,
        'createdAt': FieldValue.serverTimestamp(),
        'latitude': lat,
        'longitude': lng,
      });
    } catch (e) {
      print("FirestoreService - submitEmergencyReport Error: $e");
      throw Exception('Failed to report emergency: $e');
    }
  }

  // 16. Delete Incident
  Future<void> deleteIncident(String incidentId) async {
    try {
      print("FirestoreService: Initiating hard delete for incident $incidentId");
      await _firestore.collection('incidents').doc(incidentId).delete();
      print("FirestoreService: Successfully deleted incident $incidentId");
    } catch (e) {
      print("FirestoreService - deleteIncident Error: $e");
      throw Exception('Failed to delete incident: $e');
    }
  }

  // 17. Complete Mission (Releases ALL assigned responders)
  Future<void> completeMission(String incidentId, List<String> responderIds, String remark) async {
    final batch = _firestore.batch();
    
    // 1. Update incident: status = completed, add remark
    batch.update(_firestore.collection('incidents').doc(incidentId), {
      'status': 'completed',
      'remarks': remark,
      'completedAt': FieldValue.serverTimestamp(),
    });
    
    // 2. Update ALL responders: availability = available, clear incident
    for (String rid in responderIds) {
      batch.update(_firestore.collection('responders').doc(rid), {
        'availability': 'available',
        'assignedIncidentId': null,
      });
    }
    
    try {
      await batch.commit();
      print("FirestoreService: Mission $incidentId completed. ${responderIds.length} units released.");
    } catch (e) {
      print("FirestoreService - completeMission Error: $e");
      throw Exception('Failed to complete mission: $e');
    }
  }

  // 18. Request Mission Completion (Responder Side)
  Future<void> requestMissionCompletion(String incidentId) async {
    try {
      print("FirestoreService: Responder requesting completion for incident $incidentId");
      await _firestore.collection('incidents').doc(incidentId).update({
        'status': 'completion_pending',
        'completionRequestedAt': FieldValue.serverTimestamp(),
      });
      print("FirestoreService: Mission $incidentId set to completion_pending");
    } catch (e) {
      print("FirestoreService - requestMissionCompletion Error: $e");
      throw Exception('Failed to request mission completion: $e');
    }
  }

  // 19. Chat Methods
  Future<void> sendChatMessage(String incidentId, ChatMessage message) async {
    try {
      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      print("FirestoreService - sendChatMessage Error: $e");
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<ChatMessage>> getChatStream(String incidentId) {
    return _firestore
        .collection('incidents')
        .doc(incidentId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data(), doc.id)).toList();
    }).handleError((e) {
      print("FirestoreService - getChatStream Error: $e");
      return <ChatMessage>[];
    });
  }
}
