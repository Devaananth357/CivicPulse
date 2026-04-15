import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../models/sos_alert.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class MapProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  StreamSubscription? _sosSubscription;
  List<SosAlert> _alerts = [];
  LatLng _currentLocation = const LatLng(0, 0);
  bool _isLoading = true;

  List<SosAlert> get alerts => _alerts;
  LatLng get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;

  void initialize() async {
    _isLoading = true;
    notifyListeners();

    // 1. Get user's current location to center map
    final position = await _locationService.getLatLngPosition();
    _currentLocation = position ?? const LatLng(0, 0);

    // 2. Listen to SOS alerts
    _sosSubscription = _firestoreService.getSosAlertsStream().listen((alerts) {
      _alerts = alerts;
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  LatLng parseLocation(String loc) {
    try {
      // Robust extraction using RegEx (same as SosAlert model)
      final numberRegex = RegExp(r'[-+]?\d*\.?\d+');
      final matches = numberRegex.allMatches(loc).toList();
      
      if (matches.length >= 2) {
        final lat = double.tryParse(matches[0].group(0) ?? '');
        final lng = double.tryParse(matches[1].group(0) ?? '');
        
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint("MapProvider Location Parse Error: $e");
    }
    return const LatLng(0, 0);
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
    super.dispose();
  }
}
