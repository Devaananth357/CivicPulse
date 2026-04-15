import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import 'package:latlong2/latlong.dart';

class AIAnalysisResult {
  final int confidence;
  final String severity;
  final List<String> reasons;

  AIAnalysisResult({
    required this.confidence,
    required this.severity,
    required this.reasons,
  });
}

class EmergencyProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  String _selectedType = 'Medical'; // Default
  String _description = '';
  bool _isSubmitting = false;

  // Image related state
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;

  // Audio related state
  bool _isRecording = false;
  bool _isAudioUploading = false;
  String? _audioUrl;

  String get selectedType => _selectedType;
  bool get isSubmitting => _isSubmitting;
  File? get imageFile => _imageFile;
  String? get imageUrl => _imageUrl;
  bool get isUploading => _isUploading;
  bool get isRecording => _isRecording;
  bool get isAudioUploading => _isAudioUploading;
  String? get audioUrl => _audioUrl;
  String get description => _description;
  
  AIAnalysisResult get currentAnalysis => analyzeReport(
    type: _selectedType,
    description: _description,
    imageUrl: _imageUrl,
    audioUrl: _audioUrl,
    lat: 0.0, // Mock for real-time UI, actual GPS used on submit
    lng: 0.0,
  );

  void setSelectedType(String type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Optimize image size
      );
      
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
        _imageUrl = null; // Reset previous URL
        notifyListeners();
        await uploadToCloudinary();
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> uploadToCloudinary() async {
    if (_imageFile == null) return;

    _isUploading = true;
    notifyListeners();

    try {
      // User provided Cloudinary credentials
      const String cloudName = "dvr7yfbgr"; 
      const String uploadPreset = "civicpulse"; 
      
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      
      final request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        _imageUrl = jsonResponse['secure_url'];
      } else {
        throw Exception(jsonResponse['error']?['message'] ?? "Upload failed with status ${response.statusCode}");
      }
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // --- AUDIO RECORDING METHODS ---

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath = path.join(directory.path, 'emergency_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
        
        const config = RecordConfig();
        
        await _audioRecorder.start(config, path: filePath);
        
        _isRecording = true;
        notifyListeners();
        print("Recording started at $filePath");
      }
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      notifyListeners();
      
      if (path != null) {
        print("Recording stopped. File at: $path");
        await uploadAudioToCloudinary(File(path));
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> uploadAudioToCloudinary(File audioFile) async {
    _isAudioUploading = true;
    _audioUrl = null; // Reset previous
    notifyListeners();

    try {
      const String cloudName = "dvr7yfbgr"; 
      const String uploadPreset = "civicpulse"; 
      
      // Using 'auto' as resource type for audio
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
      
      final request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        _audioUrl = jsonResponse['secure_url'];
        print("Audio uploaded successfully: $_audioUrl");
      } else {
        throw Exception(jsonResponse['error']?['message'] ?? "Audio upload failed with status ${response.statusCode}");
      }
    } catch (e) {
      print("Cloudinary Audio Upload Error: $e");
    } finally {
      _isAudioUploading = false;
      notifyListeners();
    }
  }

  void resetAudio() {
    _audioUrl = null;
    notifyListeners();
  }

  void resetImage() {
    _imageFile = null;
    _imageUrl = null;
    notifyListeners();
  }

  int calculateAIConfidence({
    required String selectedType,
    required String? imageUrl,
    required String? audioUrl,
    required bool hasLocation,
    required String message,
  }) {
    int score = 0;

    // 1. Type selection (+10)
    if (selectedType.isNotEmpty) {
      score += 10;
    }

    // 2. Image evidence (+30)
    if (imageUrl != null && imageUrl.isNotEmpty) {
      score += 30;
    }

    // 3. Audio evidence (+30)
    if (audioUrl != null && audioUrl.isNotEmpty) {
      score += 30;
    }

    // 4. GPS Location (+10)
    if (hasLocation) {
      score += 10;
    }

    // 5. Keyword analysis (+20)
    final keywords = ['fire', 'help', 'accident', 'emergency', 'danger'];
    final lowerMessage = message.toLowerCase();
    bool hasKeyword = keywords.any((kw) => lowerMessage.contains(kw));
    if (hasKeyword) {
      score += 20;
    }

    // Cap at 100
    return score > 100 ? 100 : score;
  }

  AIAnalysisResult analyzeReport({
    required String type,
    required String description,
    required String? imageUrl,
    required String? audioUrl,
    required double? lat,
    required double? lng,
  }) {
    int score = 0;
    List<String> reasons = [];

    // A. Type weight
    final typeLower = type.toLowerCase();
    if (typeLower == 'fire') {
      score += 25;
      reasons.add("Priority incident type: Fire");
    } else if (typeLower == 'medical') {
      score += 20;
      reasons.add("Priority incident type: Medical");
    } else if (typeLower == 'crime') {
      score += 20;
      reasons.add("Priority incident type: Crime");
    } else {
      score += 10;
      reasons.add("Standard incident type");
    }

    // B. Evidence
    if (imageUrl != null && imageUrl.isNotEmpty) {
      score += 25;
      reasons.add("Visual evidence provided");
    }
    if (audioUrl != null && audioUrl.isNotEmpty) {
      score += 25;
      reasons.add("Audio evidence provided");
    }

    // C. Location
    if (lat != null && lng != null) {
      score += 10;
      reasons.add("GPS coordinates verified");
    }

    // D. Description analysis
    final highUrgency = ["fire", "explosion", "bleeding", "unconscious", "attack"];
    final mediumUrgency = ["accident", "injured", "help", "danger"];
    final lowUrgency = ["suspicious", "issue", "problem"];

    final descLower = description.toLowerCase();
    int keywordBonus = 0;

    for (var kw in highUrgency) {
      if (descLower.contains(kw)) {
        keywordBonus += 10;
      }
    }
    for (var kw in mediumUrgency) {
      if (descLower.contains(kw)) {
        keywordBonus += 5;
      }
    }
    for (var kw in lowUrgency) {
      if (descLower.contains(kw)) {
        keywordBonus += 2;
      }
    }

    if (keywordBonus > 0) {
      score += keywordBonus;
      reasons.add("Urgency keywords detected");
    }

    if (description.length > 20) {
      score += 5;
      reasons.add("Detailed description provided");
    }

    // Cap at 100
    final finalScore = score > 100 ? 100 : score;

    // Severity mapping
    String severity = "low";
    if (finalScore >= 80) {
      severity = "high";
    } else if (finalScore >= 50) {
      severity = "medium";
    }

    return AIAnalysisResult(
      confidence: finalScore,
      severity: severity,
      reasons: reasons,
    );
  }

  Future<void> submitReport(String userId, String reporterName) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      // 1. Get location with verification
      LatLng? position = await _locationService.getLatLngPosition();
      
      // 2. High-accuracy retry if 0,0 (Null Island check)
      if (position == null || (position.latitude == 0.0 && position.longitude == 0.0)) {
        print("[EmergencyProvider] Null Island detected, retrying high-accuracy GPS...");
        position = await _locationService.getLatLngPosition(); // Second attempt
      }

      // 3. Final safety check
      if (position == null || (position.latitude == 0.0 && position.longitude == 0.0)) {
        throw Exception("CRITICAL: GPS Lock Failed. Please check location settings and ensure a clear view of the sky for accurate dispatch.");
      }

      final finalMessage = _description.trim().isNotEmpty ? _description.trim() : "User reported emergency";

      final analysis = analyzeReport(
        type: _selectedType,
        description: finalMessage,
        imageUrl: _imageUrl,
        audioUrl: _audioUrl,
        lat: position.latitude,
        lng: position.longitude,
      );
      
      final reportData = {
        'type': _selectedType,
        'description': finalMessage,
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': "GPS Verified",
        },
        'status': "active",
        'aiConfidence': analysis.confidence,
        'severity': analysis.severity,
        'aiReasons': analysis.reasons,
        'imageUrl': _imageUrl ?? "",
        'audioUrl': _audioUrl ?? "",
        'userId': userId,
        'reporterName': reporterName,
      };

      await _firestoreService.submitEmergencyReport(reportData);
    } catch (e) {
      print("Error in submitReport: $e");
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
