import 'package:cloud_firestore/cloud_firestore.dart';

class Incident {
  final String? id;
  final String type;
  final String title;
  final String description;
  final String severity;
  final String location;
  final int aiConfidence;
  final String aiAnalysisTime;
  final String? aiReasoning;
  final String? aiPriority;
  final DateTime createdAt;
  final String status;
  final DateTime? completedAt;
  final List<String> aiReasons;
  final bool isSos;
  final List<String> backupRequests; // e.g. ['medic', 'fire']
  final DateTime? backupRequestedAt;
  final List<String> assignedResponderIds;
  final Map<String, dynamic>? responderDetails; // Map of responderId -> {name, imageUrl, specialization, phone}
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? audioUrl;
  final String? remarks;
  final String? reporterName;
  final String? userId;
  final int confirmCount;
  final int denyCount;

  Incident({
    this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.location,
    required this.aiConfidence,
    required this.aiAnalysisTime,
    this.aiReasoning,
    this.aiPriority,
    required this.createdAt,
    required this.status,
    this.assignedResponderIds = const [],
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.audioUrl,
    this.remarks,
    this.responderDetails,
    this.reporterName,
    this.userId,
    this.completedAt,
    this.aiReasons = const [],
    this.isSos = false,
    this.backupRequests = const [],
    this.backupRequestedAt,
    this.confirmCount = 0,
    this.denyCount = 0,
  });

  bool get isCompleted => status.toLowerCase() == 'completed' || completedAt != null;
  bool get isActive => !isCompleted;

  // Backward Compatibility Getters
  String? get assignedResponderId => assignedResponderIds.isNotEmpty ? assignedResponderIds.first : null;
  Map<String, dynamic>? get responderDetail => responderDetails != null && assignedResponderId != null 
      ? responderDetails![assignedResponderId] 
      : null;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'severity': severity,
      'location': location,
      'aiConfidence': aiConfidence,
      'aiAnalysisTime': aiAnalysisTime,
      'aiReasoning': aiReasoning,
      'aiReasons': aiReasons,
      'aiPriority': aiPriority,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'isSos': isSos,
      'backupRequests': backupRequests,
      'backupRequestedAt': backupRequestedAt != null ? Timestamp.fromDate(backupRequestedAt!) : null,
      'assignedResponderIds': assignedResponderIds,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'remarks': remarks,
      'responderDetails': responderDetails,
      'reporterName': reporterName,
      'userId': userId,
      'confirmCount': confirmCount,
      'denyCount': denyCount,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map, [String? docId]) {
    // 1. Prioritize top-level latitude/longitude
    double? lat = (map['latitude'] as num?)?.toDouble();
    double? lng = (map['longitude'] as num?)?.toDouble();

    // 2. Fallback to location object (used by mobile reporting)
    final rawLocation = map['location'];
    if (lat == null || lng == null) {
      if (rawLocation is Map) {
        lat = (rawLocation['lat'] as num?)?.toDouble();
        lng = (rawLocation['lng'] as num?)?.toDouble();
      }
    }
    
    String displayLocation = 'Coordinates Unavailable';
    if (rawLocation is String) {
      displayLocation = rawLocation;
    } else if (lat != null && lng != null) {
      displayLocation = "Sector: ${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}";
    }

    // 3. Handle Migration: assignedResponderId -> assignedResponderIds
    List<String> responderIds = [];
    if (map['assignedResponderIds'] is List) {
      responderIds = List<String>.from(map['assignedResponderIds']);
    } else if (map['assignedResponderId'] is String) {
      responderIds = [map['assignedResponderId'] as String];
    }

    return Incident(
      id: docId,
      type: map['type'] as String? ?? 'Generic',
      title: map['title'] as String? ?? 'Untitled Incident',
      description: map['description'] as String? ?? 'No description provided.',
      severity: map['severity'] as String? ?? 'Unknown',
      location: displayLocation,
      aiConfidence: (map['aiConfidence'] as num?)?.toInt() ?? 0,
      aiAnalysisTime: map['aiAnalysisTime'] as String? ?? '0.0s',
      aiReasoning: map['aiReasoning'] as String?,
      aiPriority: map['aiPriority'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'Open',
      assignedResponderIds: responderIds,
      latitude: lat,
      longitude: lng,
      imageUrl: map['imageUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
      remarks: map['remarks'] as String?,
      responderDetails: map['responderDetails'] as Map<String, dynamic>?,
      reporterName: map['reporterName'] as String?,
      userId: map['userId'] as String?,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      aiReasons: List<String>.from(map['aiReasons'] ?? []),
      isSos: map['isSos'] as bool? ?? false,
      backupRequests: List<String>.from(map['backupRequests'] ?? []),
      backupRequestedAt: (map['backupRequestedAt'] as Timestamp?)?.toDate(),
      confirmCount: (map['confirmCount'] as num?)?.toInt() ?? 0,
      denyCount: (map['denyCount'] as num?)?.toInt() ?? 0,
    );
  }
}
