import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/system_status.dart';
import '../models/incident.dart';
import '../models/sos_alert.dart';
import '../models/responder.dart';
import '../models/chat_message.dart';
import '../models/broadcast.dart';

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
          .where((inc) => inc.isActive)
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
          .where((inc) => inc.isActive)
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
  // Fixed: Refactored to in-memory filtering to avoid missing composite index errors
  // and handle potential casing inconsistencies.
  Stream<List<Incident>> getIncidentsStream() {
    return _firestore
        .collection('incidents')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .where((inc) => inc.isActive)
          .toList();
          
      // Sort by status then createdAt descending
      list.sort((a, b) {
        int statusCompare = a.status.compareTo(b.status);
        if (statusCompare != 0) return statusCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return list;
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
  // Fixed: Use in-memory filtering for consistency with active feed and casing robustness
  Stream<List<Incident>> getCompletedIncidentsStream() {
    return _firestore
        .collection('incidents')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .where((inc) => inc.isCompleted)
          .toList();
          
      // Sort by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((e) {
      print("FirestoreService - getCompletedIncidentsStream Error: $e");
      return <Incident>[];
    });
  }

  // 7a. Fetch ALL incidents as a stream (no filters)
  Stream<List<Incident>> getAllIncidentsStream() {
    return _firestore
        .collection('incidents')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Incident.fromMap(doc.data(), doc.id)).toList();
    }).handleError((e) {
      print("FirestoreService - getAllIncidentsStream Error: $e");
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
    
    final String spec = (responderData['specialization'] ?? 'General').toString().toLowerCase();

    // 2. Update incident with NEW responder details and ID
    batch.update(_firestore.collection('incidents').doc(incidentId), {
      'assignedResponderIds': FieldValue.arrayUnion([responderId]),
      // Only set status to assigned if it wasn't already being handled (in_progress)
      'status': 'assigned', 
      'responderDetails.$responderId': details,
      // Backward compatibility for existing UI
      'assignedResponderId': responderId,
      'backupRequests': FieldValue.arrayRemove([spec]),
    });
    
    // 3. Update responder status (Keep as 'available' so they see the Alert Screen to accept)
    batch.update(_firestore.collection('responders').doc(responderId), {
      'assignedIncidentId': incidentId,
      // REMOVED: 'availability': 'busy', 
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

      // Update system status to Danger when a new emergency is reported
      await _updateSystemStatus('Danger');
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

      // Cleanup associated broadcasts to prevent "ghost warnings"
      try {
        final linkedBroadcasts = await _firestore
            .collection('broadcasts')
            .where('incidentId', isEqualTo: incidentId)
            .get();
        
        if (linkedBroadcasts.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in linkedBroadcasts.docs) {
            // SOFT-DELETE: Deactivate first, then delete
            batch.update(doc.reference, {'isActive': false});
            batch.delete(doc.reference);
          }
          await batch.commit();
          print("FirestoreService: Deactivated and cleaned up ${linkedBroadcasts.docs.length} ghost broadcasts for incident $incidentId");
        }
      } catch (e) {
        print("Warning: Failed to cleanup linked broadcasts: $e");
      }

      // Cleanup associated legacy SOS alerts
      try {
        final legacyAlerts = await _firestore
            .collection('sos_alerts')
            .where('incidentId', isEqualTo: incidentId)
            .get();
        
        if (legacyAlerts.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in legacyAlerts.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          print("FirestoreService: Deleted ${legacyAlerts.docs.length} legacy alerts for incident $incidentId");
        }
      } catch (e) {
        print("Warning: Failed to cleanup legacy alerts: $e");
      }
      
      // Check if we should revert to Safe mode after deletion
      await _checkAndRevertStatus();
    } catch (e) {
      print("FirestoreService - deleteIncident Error: $e");
      throw Exception('Failed to delete incident: $e');
    }
  }

  // 17. Complete Mission (Releases ALL assigned responders)
  Future<void> completeMission(String incidentId, List<String> responderIds, String remark) async {
    try {
      // 1. Fetch incident data first to get the userId for status reset
      final incidentDoc = await _firestore.collection('incidents').doc(incidentId).get();
      final incidentData = incidentDoc.data();
      final String? victimId = incidentData?['userId'];

      final batch = _firestore.batch();
      
      // 2. Update incident: status = completed, add remark
      batch.update(_firestore.collection('incidents').doc(incidentId), {
        'status': 'completed',
        'remarks': remark,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // 3. Update ALL responders: availability = available, clear incident, increment missions completed
      for (String rid in responderIds) {
        batch.update(_firestore.collection('responders').doc(rid), {
          'availability': 'available',
          'assignedIncidentId': null,
          'missionsCompleted': FieldValue.increment(1),
        });
      }

      // 4. Reset User Status to safe
      if (victimId != null) {
        // Fetch user document to check current status for conditional update
        final userDoc = await _firestore.collection('users').doc(victimId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final currentStatus = (userData['status'] ?? 'safe').toString().toLowerCase();
          final bool isCurrentlyInDanger = userData['isInDanger'] == true || currentStatus == 'danger';

          if (isCurrentlyInDanger) {
            batch.update(_firestore.collection('users').doc(victimId), {
              'status': 'safe',
              'isInDanger': false,
              'lastSafeAt': FieldValue.serverTimestamp(),
              'lastActive': FieldValue.serverTimestamp(),
            });
            print("👤 FirestoreService: User $victimId confirmed SAFE after completion.");
          }
        }
      }

      // 5. Cleanup associated broadcasts to prevent "ghost warnings"
      final linkedBroadcasts = await _firestore
          .collection('broadcasts')
          .where('incidentId', isEqualTo: incidentId)
          .get();
      
      for (var doc in linkedBroadcasts.docs) {
        batch.update(doc.reference, {'isActive': false}); // Deactivate
        batch.delete(doc.reference);
      }
      if (linkedBroadcasts.docs.isNotEmpty) {
        print("📢 FirestoreService: Deactivated and Cleared ${linkedBroadcasts.docs.length} broadcasts for closed incident.");
      }

      // 6. SYNCHRONIZATION FIX: Clear legacy sos_alerts entries to prevent lingering 'Danger' status
      try {
        final legacyAlerts = await _firestore
            .collection('sos_alerts')
            .where('incidentId', isEqualTo: incidentId)
            .get();
        
        for (var doc in legacyAlerts.docs) {
          batch.update(doc.reference, {
            'status': 'completed',
            'resolvedAt': FieldValue.serverTimestamp(),
          });
        }

        // Fail-safe: Also search by victimId if no direct incident link found
        if (legacyAlerts.docs.isEmpty && victimId != null) {
          final orphanedAlerts = await _firestore
              .collection('sos_alerts')
              .where('userId', isEqualTo: victimId)
              .where('status', isEqualTo: 'active')
              .get();
          
          for (var doc in orphanedAlerts.docs) {
            batch.update(doc.reference, {
              'status': 'completed',
              'resolvedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (e) {
        print("Warning: Legacy SOS cleanup failed: $e");
      }
      
      await batch.commit();
      print("FirestoreService: Mission $incidentId completed. ${responderIds.length} units released.");
      
      // Check if we should revert global system mode
      await _checkAndRevertStatus();
    } catch (e) {
      print("FirestoreService - completeMission Error: $e");
      throw Exception('Failed to complete mission: $e');
    }
  }

  // Helper: Update system status document
  Future<void> updateGlobalStatus(String status) async {
    try {
      await _firestore.collection('system_status').doc('current').set({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("🔥 System Status manually updated to: $status");
    } catch (e) {
      print("Error updating system status: $e");
    }
  }

  // Helper: Internal update
  Future<void> _updateSystemStatus(String status) async {
    await updateGlobalStatus(status);
  }

  // Helper: Revert to Safe mode if no more active incidents
  Future<void> _checkAndRevertStatus() async {
    try {
      // 1. Check Incidents
      final activeIncidents = await _firestore
          .collection('incidents')
          .get();
      
      final bool hasActiveIncident = activeIncidents.docs.any((doc) {
        final data = doc.data();
        final String status = (data['status'] ?? '').toString().toLowerCase();
        // Robust check: any status that isn't 'completed' is considered active
        return status != 'completed' && status != 'resolved' && status != 'closed';
      });

      if (hasActiveIncident) return; // Still active incidents, stop here

      // 2. Check SOS Alerts
      final activeSos = await _firestore
          .collection('sos_alerts')
          .get();
      
      final bool hasActiveSos = activeSos.docs.any((doc) {
        final data = doc.data();
        final String status = (data['status'] ?? '').toString().toLowerCase();
        return status == 'active' || status == 'open';
      });

      // 3. If neither has active items, revert to Safe
      if (!hasActiveSos) {
        await _updateSystemStatus('Safe');
      }
    } catch (e) {
      print("Error checking active incidents for status reversal: $e");
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
  // 17. Request Backup for an incident
  Future<void> requestBackup(String incidentId, String specialization) async {
    try {
      final docRef = _firestore.collection('incidents').doc(incidentId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Incident not found");
        
        final List<String> currentBackups = List<String>.from(snapshot.data()?['backupRequests'] ?? []);
        if (!currentBackups.contains(specialization.toLowerCase())) {
          currentBackups.add(specialization.toLowerCase());
        }
        
        transaction.update(docRef, {
          'backupRequests': currentBackups,
          'backupRequestedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print("FirestoreService - requestBackup Error: $e");
      throw Exception('Failed to request backup: $e');
    }
  }

  // 20. Crowd Verification Methods
  Future<bool> hasUserVerifiedIncident(String userId, String incidentId) async {
    try {
      final snapshot = await _firestore
          .collection('verifications')
          .where('userId', isEqualTo: userId)
          .where('incidentId', isEqualTo: incidentId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("FirestoreService - hasUserVerifiedIncident Error: $e");
      return false;
    }
  }

  Future<void> submitVerification(String userId, String incidentId, String response) async {
    final batch = _firestore.batch();
    
    // 1. Create verification document
    final verifRef = _firestore.collection('verifications').doc();
    batch.set(verifRef, {
      'userId': userId,
      'incidentId': incidentId,
      'response': response,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // 2. Atomically increment incident counts
    final incidentRef = _firestore.collection('incidents').doc(incidentId);
    batch.update(incidentRef, {
      response == 'confirm' ? 'confirmCount' : 'denyCount': FieldValue.increment(1),
    });
    
    await batch.commit();
  }

  Stream<List<Incident>> getRecentIncidentsStream({Duration maxAge = const Duration(minutes: 10)}) {
    final threshold = DateTime.now().subtract(maxAge);
    
    // Using simple streaming and in-memory filter to avoid index requirements
    return _firestore
        .collection('incidents')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .where((inc) => inc.createdAt.isAfter(threshold) && inc.status != 'completed')
          .toList();
    }).handleError((e) {
      print("FirestoreService - getRecentIncidentsStream Error: $e");
      return <Incident>[];
    });
  }

  // --- MANUAL BROADCAST METHODS ---

  Future<void> sendBroadcast(Broadcast broadcast) async {
    try {
      await _firestore.collection('broadcasts').add(broadcast.toFirestore());
      print("📢 Broadcast sent: ${broadcast.message}");
    } catch (e) {
      print("FirestoreService - sendBroadcast Error: $e");
      throw Exception('Failed to send broadcast: $e');
    }
  }

  Stream<List<Broadcast>> getActiveBroadcastsStream() {
    final now = DateTime.now();
    return _firestore
        .collection('broadcasts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Broadcast.fromFirestore(doc))
          .where((b) => b.expiresAt.isAfter(now))
          .toList();
    }).handleError((e) {
      print("FirestoreService - getActiveBroadcastsStream Error: $e");
      return <Broadcast>[];
    });
  }

  // --- USER PROFILE METHODS ---

  Future<void> updateUserStatus(String uid, String status) async {
    try {
      final bool settingToDanger = status.toLowerCase() == 'danger';
      
      // If setting to safe, we apply the conditional check: only update if currently in danger
      if (!settingToDanger) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final currentStatus = (userData['status'] ?? 'safe').toString().toLowerCase();
          final bool isCurrentlyInDanger = userData['isInDanger'] == true || currentStatus == 'danger';

          if (!isCurrentlyInDanger) {
            print("👤 FirestoreService: User $uid already safe, skipping update.");
            return;
          }
        }
      }

      await _firestore.collection('users').doc(uid).update({
        'status': status,
        'isInDanger': settingToDanger,
        'lastActive': FieldValue.serverTimestamp(),
        if (!settingToDanger) 'lastSafeAt': FieldValue.serverTimestamp(),
      });
      print("👤 User status updated for $uid to $status (isInDanger: $settingToDanger)");
    } catch (e) {
      print("FirestoreService - updateUserStatus Error: $e");
      throw Exception('Failed to update user status: $e');
    }
  }

  // 21. Fail-Safe: Check if incident is active (not completed/deleted)
  Future<bool> isIncidentActive(String incidentId) async {
    try {
      final doc = await _firestore.collection('incidents').doc(incidentId).get();
      if (!doc.exists) return false;
      
      final status = (doc.data()?['status'] ?? '').toString().toLowerCase();
      return status != 'completed' && status != 'resolved' && status != 'closed';
    } catch (e) {
      print("Error checking incident state: $e");
      return false; // Assume inactive if error to be safe
    }
  }
}
