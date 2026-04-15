import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/responder.dart';
import '../../../models/incident.dart';
import '../../../services/firestore_service.dart';

class ResponderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid;

  int _currentTabIndex = 0;
  Responder? _currentResponder;
  Incident? _assignedIncident;
  bool _isLoadingIncident = false;

  StreamSubscription<Responder?>? _responderSubscription;
  StreamSubscription<Incident?>? _incidentSubscription;
  Timer? _locationTimer;

  int get currentTabIndex => _currentTabIndex;
  Responder? get currentResponder => _currentResponder;
  Incident? get assignedIncident => _assignedIncident;
  bool get isLoadingIncident => _isLoadingIncident;

  ResponderProvider({required this.uid}) {
    _initResponderStream();
    _startLocationUpdates();
  }

  void _initResponderStream() {
    _responderSubscription = _firestoreService.getResponderStream(uid).listen((responder) {
      _currentResponder = responder;
      notifyListeners();

      if (responder?.assignedIncidentId != null) {
        _initIncidentStream(responder!.assignedIncidentId!);
      } else {
        _assignedIncident = null;
        _stopIncidentStream();
        notifyListeners();
      }
    });
  }

  void _startLocationUpdates() {
    // Initial update
    _updateLocation();
    
    // Periodic update every minute
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      print("[GPS] Starting update cycle...");
      
      // 1. Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print("[GPS] Permission status: $permission");
      
      if (permission == LocationPermission.denied) {
        print("[GPS] Requesting permission...");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("[GPS] Permission denied.");
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print("[GPS] Permission denied forever.");
        return;
      }

      // 2. Get current position with timeout
      Position? position;
      try {
        print("[GPS] Requesting current position (15s timeout)...");
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        print("[GPS] High-accuracy request failed or timed out: $e");
        print("[GPS] Falling back to last known position...");
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        print("[GPS WARNING] No location data available after timeout and fallback.");
        return;
      }

      // 3. Null-Island Protection: Do not sync if coords are exactly 0,0
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        print("[GPS SOURCE ERROR] Source returned exactly 0,0. Skipping database write to avoid distance calculation errors.");
        return;
      }

      // 4. Verification: Ensure CID is valid
      if (uid.trim().isEmpty) {
        print("[GPS CRITICAL] Attempted to update location with EMPTY UID. Aborting.");
        return;
      }

      // 5. Sync with Firestore
      await _firestoreService.updateResponderLocation(
        uid, 
        position.latitude, 
        position.longitude
      );
      
      print("[GPS SUCCESS] Dispatched location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} for CID: $uid");
    } catch (e) {
      print("[GPS CRITICAL ERROR] $e");
    }
  }

  void _initIncidentStream(String incidentId) {
    // Prevent multiple subscriptions
    if (_incidentSubscription != null && _assignedIncident?.id == incidentId) return;
    
    _isLoadingIncident = true;
    notifyListeners();

    _stopIncidentStream();
    _incidentSubscription = _firestoreService.getIncidentStream(incidentId).listen((incident) {
      _assignedIncident = incident;
      _isLoadingIncident = false;
      notifyListeners();
    });
  }

  void _stopIncidentStream() {
    _incidentSubscription?.cancel();
    _incidentSubscription = null;
  }

  Future<void> acceptMission() async {
    if (_currentResponder == null || _assignedIncident == null) return;
    try {
      await _firestoreService.acceptMission(_currentResponder!.id, _assignedIncident!.id!);
      setTabIndex(1); // Auto-navigate to Map tab
    } catch (e) {
      print("Error accepting mission: $e");
      rethrow;
    }
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> rejectMission() async {
    if (_currentResponder == null || _assignedIncident == null) return;
    try {
      await _firestoreService.rejectMission(_currentResponder!.id, _assignedIncident!.id!);
    } catch (e) {
      print("Error rejecting mission: $e");
      rethrow;
    }
  }

  Future<void> requestCompletion() async {
    if (_assignedIncident == null) return;
    try {
      await _firestoreService.requestMissionCompletion(_assignedIncident!.id!);
    } catch (e) {
      print("Error requesting completion: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _responderSubscription?.cancel();
    _incidentSubscription?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }
}
