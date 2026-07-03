import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/system_status.dart';
import '../../models/incident.dart';
import '../../services/firestore_service.dart';
import '../../models/broadcast.dart';
import '../../services/location_service.dart';
import '../../services/aqi_service.dart';
import '../../models/air_quality.dart';
import 'package:latlong2/latlong.dart';

class HomeProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  SystemStatus? _systemStatus;
  String? _currentUserId;
  String? _userPersonalStatus;
  Incident? _latestIncident;
  List<Incident> _verifiableIncidents = [];
  final Set<String> _dismissedIncidentIds = {}; 
  int _respondersCount = 0;
  bool _isLoading = true;
  Broadcast? _activeBroadcast;
  final Set<String> _dismissedBroadcastIds = {};
  final LocationService _locationService = LocationService();
  final AqiService _aqiService = AqiService();
  final Distance _distance = const Distance();
  
  AirQuality? _airQuality;

  StreamSubscription<SystemStatus>? _statusSubscription;
  StreamSubscription<Incident?>? _incidentSubscription;
  StreamSubscription<List<Incident>>? _recentIncidentsSubscription;
  StreamSubscription<List<Broadcast>>? _broadcastSubscription;

  // Getters
  SystemStatus? get systemStatus => _systemStatus;
  
  // The "Effective" status prioritized per-user safety and nearby emergencies
  String get effectiveStatus {
    // 1. Priority: Personal Danger (User is in an active SOS)
    if (_userPersonalStatus?.toLowerCase() == 'danger') return 'Danger';

    // 2. Priority: Nearby Danger (User is within a broadcast radius)
    if (_activeBroadcast != null) return 'Danger';

    // 3. Fallback: Personal Status or System Status
    return _userPersonalStatus ?? _systemStatus?.status ?? 'Safe';
  }

  Incident? get latestIncident => _latestIncident;
  List<Incident> get verifiableIncidents => _verifiableIncidents
    .where((inc) => !_dismissedIncidentIds.contains(inc.id) && inc.userId != _currentUserId)
    .toList();
  int get respondersCount => _respondersCount;
  bool get isLoading => _isLoading;
  Broadcast? get activeBroadcast => _activeBroadcast;
  AirQuality? get airQuality => _airQuality;

  Future<void> initialize([String? userId, String? personalStatus]) async {
    print("🚀 HomeProvider: Initialization Starting for User: $userId (Status: $personalStatus)");
    _currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    _userPersonalStatus = personalStatus;
    _isLoading = true;
    notifyListeners();

    listenToSystemStatus();
    listenToIncident();
    listenToRecentIncidents();
    listenToActiveBroadcasts();
    
    // Fetch responders count and Air Quality in parallel for faster app startup
    await Future.wait([
      fetchRespondersCount(),
      fetchAirQuality(),
    ]);

    _isLoading = false;
    print("🚀 HomeProvider: Page Initialized Successfully.");
    notifyListeners();
  }

  // Sync user details from AuthProvider
  void syncWithAuth(String? userId, String? personalStatus) {
    bool changed = false;
    if (_currentUserId != userId) {
      _currentUserId = userId;
      changed = true;
    }
    if (_userPersonalStatus != personalStatus) {
      _userPersonalStatus = personalStatus;
      changed = true;
    }
    
    if (changed) {
      print("🔥 Personal Status Update: $_userPersonalStatus");
      print("🚀 HomeProvider: Synced with Auth (User: $userId, Status: $personalStatus)");
      notifyListeners();
      
      // Re-evaluate broadcasts with the new user ID
      if (_currentUserId != null) {
        _checkActiveBroadcasts();
      }
    }
  }

  // Refactored broadcast check into a standalone method for re-usability
  Future<void> _checkActiveBroadcasts() async {
    final broadcasts = await _firestoreService.getActiveBroadcastsStream().first;
    _processBroadcastSnapshots(broadcasts);
  }

  void _processBroadcastSnapshots(List<Broadcast> broadcasts) async {
      print("📢 HomeProvider: Processing ${broadcasts.length} active broadcasts. User: $_currentUserId");
      
      if (broadcasts.isEmpty) {
        _activeBroadcast = null;
        notifyListeners();
        return;
      }

      final userLatLng = await _locationService.getLatLngPosition();
      if (userLatLng == null) {
        print("📢 HomeProvider: User location unavailable, skipping broadcast check");
        return;
      }

      Broadcast? foundBroadcast;
      for (var b in broadcasts) {
        if (!b.isActive) continue; // Skip inactive broadcasts
        if (_dismissedBroadcastIds.contains(b.id)) continue;
        
        // CRITICAL FIX: Skip if this broadcast was reported by the current user
        if (b.excludeUserId != null && b.excludeUserId == _currentUserId) {
          print("📢 HomeProvider: Skipping alert ${b.id} because current user is the reporter.");
          continue;
        }

        // FAIL-SAFE: If linked to an incident, verify it's still active
        if (b.incidentId != null) {
          final isIncidentActive = await _firestoreService.isIncidentActive(b.incidentId!);
          if (!isIncidentActive) {
            print("📢 HomeProvider: Incident ${b.incidentId} is no longer active. Ignoring linked broadcast.");
            continue;
          }
        }

        final double distMeters = _distance.as(LengthUnit.Meter, userLatLng, b.center);
        if (distMeters <= b.radius) {
          foundBroadcast = b;
          break;
        }
      }

      if (_activeBroadcast?.id != foundBroadcast?.id) {
        _activeBroadcast = foundBroadcast;
        notifyListeners();
      }
  }

  void listenToSystemStatus() {
    _statusSubscription?.cancel();
    _statusSubscription = _firestoreService.getSystemStatusStream().listen((status) {
      print("🔥 Live Status Update: ${status.status}");
      _systemStatus = status;
      notifyListeners();
    });
  }

  void listenToIncident() {
    _incidentSubscription?.cancel();
    
    final stream = _currentUserId != null 
        ? _firestoreService.getLatestIncidentForUser(_currentUserId!)
        : _firestoreService.getLatestIncident();

    _incidentSubscription = stream.listen((incident) {
      print("🎯 HomeProvider: Stream Update Received - ID: ${incident?.id}, Status: ${incident?.status}, Assigned: ${incident?.assignedResponderIds.length}");
      _latestIncident = incident;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> fetchRespondersCount() async {
    _respondersCount = await _firestoreService.getAvailableRespondersCount();
    print("🔥 Available Responders: $_respondersCount");
    notifyListeners();
  }

  Future<void> fetchSystemStatus() async {
    _systemStatus = await _firestoreService.getSystemStatus();
    print("🔥 Manual Status Fetch: ${_systemStatus?.status}");
    notifyListeners();
  }

  void listenToRecentIncidents() {
    _recentIncidentsSubscription?.cancel();
    _recentIncidentsSubscription = _firestoreService.getRecentIncidentsStream().listen((incidents) {
      _verifiableIncidents = incidents;
      notifyListeners();
    });
  }

  void dismissIncident(String incidentId) {
    _dismissedIncidentIds.add(incidentId);
    notifyListeners();
  }

  void listenToActiveBroadcasts() {
    _broadcastSubscription?.cancel();
    _broadcastSubscription = _firestoreService.getActiveBroadcastsStream().listen((broadcasts) {
      _processBroadcastSnapshots(broadcasts);
    });
  }

  void dismissBroadcast() {
    if (_activeBroadcast != null && _activeBroadcast!.id != null) {
      _dismissedBroadcastIds.add(_activeBroadcast!.id!);
      _activeBroadcast = null;
      notifyListeners();
    }
  }

  Future<void> verifyIncident(String incidentId, String response) async {
    if (_currentUserId == null) return;
    
    // Optimistic UI: Remove from list immediately
    _dismissedIncidentIds.add(incidentId);
    notifyListeners();

    try {
      await _firestoreService.submitVerification(_currentUserId!, incidentId, response);
    } catch (e) {
      print("HomeProvider - verifyIncident Error: $e");
      // Could revert optimistic UI here if needed
    }
  }

  Future<void> toggleGlobalStatus(String status) async {
    await _firestoreService.updateGlobalStatus(status);
  }

  Future<void> fetchAirQuality() async {
    final latLng = await _locationService.getLatLngPosition();
    if (latLng == null) {
      print("📢 HomeProvider: Location unavailable for AQI fetch");
      return;
    }

    print("📢 HomeProvider: Fetching AQI for Location: ${latLng.latitude}, ${latLng.longitude} (Chennai Expected)");
    _airQuality = await _aqiService.getAirQuality(latLng.latitude, latLng.longitude);
    print("📢 HomeProvider: API Response City: ${_airQuality?.cityName}");
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _incidentSubscription?.cancel();
    _recentIncidentsSubscription?.cancel();
    _broadcastSubscription?.cancel();
    super.dispose();
  }
}
