import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/system_status.dart';
import '../../models/incident.dart';
import '../../services/firestore_service.dart';

class HomeProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  SystemStatus? _systemStatus;
  String? _currentUserId;
  Incident? _latestIncident;
  int _respondersCount = 0;
  bool _isLoading = true;

  StreamSubscription<SystemStatus>? _statusSubscription;
  StreamSubscription<Incident?>? _incidentSubscription;

  // Getters
  SystemStatus? get systemStatus => _systemStatus;
  Incident? get latestIncident => _latestIncident;
  int get respondersCount => _respondersCount;
  bool get isLoading => _isLoading;

  Future<void> initialize([String? userId]) async {
    print("🚀 HomeProvider: Initialization Starting for User: $userId");
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    listenToSystemStatus();
    listenToIncident();
    await fetchRespondersCount();

    _isLoading = false;
    print("🚀 HomeProvider: Page Initialized Successfully.");
    notifyListeners();
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

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _incidentSubscription?.cancel();
    super.dispose();
  }
}
