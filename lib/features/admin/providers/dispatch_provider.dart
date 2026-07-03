import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../models/incident.dart';
import '../../../models/responder.dart';
import '../../../services/firestore_service.dart';

class DispatchProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  Incident? _selectedIncident;
  List<Map<String, dynamic>> _suggestedResponders = [];
  bool _isAutoAssigning = false;
  bool _isAnalyzing = false;
  
  List<Incident> _allIncidents = [];
  List<Responder> _allResponders = [];
  
  StreamSubscription? _incidentsSubscription;
  StreamSubscription? _respondersSubscription;
  Timer? _sentinelTimer;

  // Smart Broadcast Trigger members
  final Set<String> _promptedIncidentIds = {};
  final StreamController<Incident> _pendingBroadcastPromptController = StreamController<Incident>.broadcast();
  bool _isFirstLoad = true;

  // Rule: Only auto-assign incidents created AFTER this session started
  final DateTime _sessionStartTime = DateTime.now();

  Incident? get selectedIncident => _selectedIncident;
  List<Map<String, dynamic>> get suggestedResponders => _suggestedResponders;
  bool get isAutoAssigning => _isAutoAssigning;
  bool get isAnalyzing => _isAnalyzing;
  Stream<Incident> get pendingBroadcastPromptStream => _pendingBroadcastPromptController.stream;

  DispatchProvider() {
    _initSentinel();
  }

  void _initSentinel() {
    _incidentsSubscription = _firestoreService.getAllIncidentsStream().listen((incidents) {
      _checkStatusTransitions(incidents);
      _allIncidents = incidents;
      _updateSuggestions();
    });

    _respondersSubscription = _firestoreService.getRespondersStream().listen((responders) {
      _allResponders = responders;
      _updateSuggestions();
    });

    // Run sentinel check every 5 seconds
    _sentinelTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkAndAutoAssign();
    });
  }

  void _checkStatusTransitions(List<Incident> currentIncidents) {
    if (_isFirstLoad) {
      // On first load, mark all existing assigned incidents as "prompted" to avoid spamming the admin
      for (var inc in currentIncidents) {
        if (inc.status.toLowerCase() == 'assigned' && inc.id != null) {
          _promptedIncidentIds.add(inc.id!);
        }
      }
      _isFirstLoad = false;
      return;
    }

    for (var inc in currentIncidents) {
      if (inc.id == null) continue;
      
      // If incident is now 'assigned' and we haven't prompted for it yet
      if (inc.status.toLowerCase() == 'assigned' && !_promptedIncidentIds.contains(inc.id)) {
        _promptedIncidentIds.add(inc.id!);
        _pendingBroadcastPromptController.add(inc);
        print("🚨 Smart Trigger: Detected assigned incident ${inc.id}. Triggering prompt.");
      }
    }
  }

  // Allow UI to manually mark as ignored or handled
  void markIncidentAsPrompted(String incidentId) {
    _promptedIncidentIds.add(incidentId);
  }

  void _updateSuggestions() {
    if (_selectedIncident != null) {
      try {
        final updatedIncident = _allIncidents.firstWhere((i) => i.id == _selectedIncident!.id);
        _selectedIncident = updatedIncident;
        _suggestedResponders = _calculateSuggestions(updatedIncident, _allResponders);
        notifyListeners();
      } catch (e) {
        // If incident was deleted, clear. If it was completed, keep it but clear suggestions
        if (_selectedIncident != null && _selectedIncident!.isCompleted) {
            _suggestedResponders = [];
            notifyListeners();
        } else {
            clearSelection();
        }
      }
    }
  }

  void selectIncident(Incident incident, List<Responder> responders) {
    _selectedIncident = incident;
    _suggestedResponders = _calculateSuggestions(incident, responders);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIncident = null;
    _suggestedResponders = [];
    notifyListeners();
  }

  List<Map<String, dynamic>> _calculateSuggestions(Incident incident, List<Responder> responders) {
    if (incident.latitude == null || incident.longitude == null) return [];

    final incidentLatLng = LatLng(incident.latitude!, incident.longitude!);
    final Distance distance = const Distance();

    // 1. Filter only for AVAILABLE responders
    final availableResponders = responders.where((r) => r.availability == 'available').toList();

    // 2. Map responders to results with compatibility score and distance
    final List<Map<String, dynamic>> results = availableResponders.map((r) {
      final double distKm = distance.as(LengthUnit.Meter, incidentLatLng, LatLng(r.latitude, r.longitude)) / 1000;
      final double score = _getCompatibilityScore(r.specialization, incident.type);
      
      return {
        'responder': r,
        'distance': distKm,
        'score': score,
      };
    }).toList();

    // 3. Rank: Highest Score first, then Nearest Distance
    results.sort((a, b) {
      // First compare scores (descending)
      final scoreCompare = (b['score'] as double).compareTo(a['score'] as double);
      if (scoreCompare != 0) return scoreCompare;
      
      // If scores are equal, compare distance (ascending)
      return (a['distance'] as double).compareTo(b['distance'] as double);
    });

    // Provide up to 10 suggestions for better manual selection range
    return results.take(10).toList();
  }

  double _getCompatibilityScore(String specialization, String incidentType) {
    final spec = specialization.toLowerCase();
    final type = incidentType.toLowerCase();

    // Exact match or Generic
    if (spec == type || type == 'generic') return 1.0;

    // Direct Mappings
    if (type.contains('crime') && spec.contains('police')) return 1.0;
    if (type.contains('medical') && spec.contains('medic')) return 1.0;
    if (type.contains('fire') && spec.contains('fire')) return 1.0;
    if (type.contains('accident') && (spec.contains('police') || spec.contains('medic'))) return 0.9;

    // Complementary Support (Cross-Team)
    if (type.contains('fire') && (spec.contains('medic') || spec.contains('police'))) return 0.7; // Fire needs medics/security
    if (type.contains('crime') && spec.contains('medic')) return 0.6; // Crime scenes might need medics

    // General fallback for all available responders
    return 0.5;
  }

  void _checkAndAutoAssign() {
    final now = DateTime.now();
    
    for (var incident in _allIncidents) {
      // 1. AI Logic for Backup Auto-Assignment (15s timeout)
      if (incident.backupRequests.isNotEmpty && incident.backupRequestedAt != null) {
        final backupAge = now.difference(incident.backupRequestedAt!).inSeconds;
        if (backupAge >= 15) {
          print("Sentinel: Backup timeout reached for incident ${incident.id}. AI Auto-assigning...");
          _autoAssignBackup(incident);
        }
      }

      // 2. Original AI Logic for Initial Auto-Assignment (60s timeout)
      if (incident.status.toLowerCase() != 'open') continue;
      
      // Rule 2: Skip if Admin is currently investigating this incident
      if (_selectedIncident?.id == incident.id) continue;
      
      // Rule 3: Session check - Only incidents created AFTER this session started
      if (incident.createdAt.isBefore(_sessionStartTime)) continue;
      
      // Rule 4: Age check - 60 seconds
      final ageSeconds = now.difference(incident.createdAt).inSeconds;
      if (ageSeconds >= 60) {
        print("Sentinel: Initial Auto-dispatch for incident ${incident.id}");
        _autoAssign(incident);
      }
    }
  }

  Future<void> _autoAssignBackup(Incident incident) async {
    for (var spec in incident.backupRequests) {
      // Calculate suggestions specifically for this required backup specialization
      final specSuggestions = _calculateSuggestions(incident, _allResponders)
          .where((s) => (s['responder'] as Responder).specialization.toLowerCase() == spec.toLowerCase())
          .toList();
      
      if (specSuggestions.isNotEmpty) {
        try {
          final nearest = specSuggestions.first['responder'] as Responder;
          print("Sentinel AI: Dispatched $spec backup (${nearest.id}) to incident ${incident.id}");
          await _firestoreService.assignResponderToIncident(nearest.id, incident.id!);
        } catch (e) {
          print("Sentinel AI backup error: $e");
        }
      }
    }
  }

  Future<void> _autoAssign(Incident incident) async {
    final suggestions = _calculateSuggestions(incident, _allResponders);
    if (suggestions.isEmpty) return;
    
    try {
      final nearest = suggestions.first['responder'] as Responder;
      await _firestoreService.assignResponderToIncident(nearest.id, incident.id!);
    } catch (e) {
      print("Sentinel error auto-assigning: $e");
    }
  }

  Future<void> manualAssign(String responderId) async {
    if (_selectedIncident == null) return;
    try {
      await _firestoreService.assignResponderToIncident(responderId, _selectedIncident!.id!);
      clearSelection();
    } catch (e) {
      print("Manual assign error: $e");
      rethrow;
    }
  }

  Future<void> analyzeIncident(String incidentId) async {
    _isAnalyzing = true;
    notifyListeners();
    try {
      final incident = _allIncidents.firstWhere((i) => i.id == incidentId);
      final response = await http.post(
        Uri.parse('http://localhost:5005/analyzeIncident'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'incidentId': incident.id,
          'description': incident.description,
          'imageUrl': incident.imageUrl,
          'location': incident.location,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Analysis failed: ${response.body}');
      }
      print("AI Analysis successful for incident $incidentId");
    } catch (e) {
      print("Error analyzing incident: $e");
      rethrow;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> deleteSelectedIncident(BuildContext context) async {
    if (_selectedIncident == null) return;
    await deleteIncidentById(context, _selectedIncident!.id!);
  }

  Future<void> deleteIncidentById(BuildContext context, String incidentId) async {
    try {
      // 1. Find the incident to check its state before deletion
      try {
        final incident = _allIncidents.firstWhere((i) => i.id == incidentId);
        
        // 2. Logic: If SOS is deleted (denied/cleared), reset user to Safe
        // Trigger for ANY SOS type or isSos flag, regardless of assignment status
        if ((incident.type.toUpperCase() == 'SOS' || incident.isSos) && incident.userId != null) {
          print("🛡️ Admin cleared SOS incident ($incidentId). Resetting user ${incident.userId} to Safe.");
          await _firestoreService.updateUserStatus(incident.userId!, 'safe');
        } else {
          print("🛡️ Admin deleted non-SOS incident or no UserID present: ${incident.type}");
        }
      } catch (e) {
        print("Note: Incident object not found in local feed during delete check: $e");
      }

      await _firestoreService.deleteIncident(incidentId);
      if (_selectedIncident?.id == incidentId) {
        clearSelection();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incident successfully removed from system"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete incident: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
      rethrow;
    }
  }

  Future<void> completeSelectedIncident(String remark) async {
    if (_selectedIncident == null || _selectedIncident!.assignedResponderIds.isEmpty) return;
    try {
      await _firestoreService.completeMission(
        _selectedIncident!.id!, 
        _selectedIncident!.assignedResponderIds, 
        remark
      );
      clearSelection();
    } catch (e) {
      print("Complete mission error: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _incidentsSubscription?.cancel();
    _respondersSubscription?.cancel();
    _sentinelTimer?.cancel();
    _pendingBroadcastPromptController.close();
    super.dispose();
  }
}
