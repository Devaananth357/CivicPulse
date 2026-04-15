import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum MessageType { user, ai }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.type,
    required this.timestamp,
  });
}

class AIAssistantProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Incident-specific data
  final Map<String, Map<String, List<String>>> _incidentData = {
    "Fire": {
      "suggestions": ["How to exit safely?", "Using a fire extinguisher", "Treating smoke inhalation"],
      "measures": ["Stay low to the ground", "Check doors for heat", "Call emergency services", "Don't use elevators"]
    },
    "Medical": {
      "suggestions": ["Performing CPR", "Stopping heavy bleeding", "Choking first aid"],
      "measures": ["Check pulse and breathing", "Keep patient warm", "Do not move if spinal injury suspected", "Apply pressure to wounds"]
    },
    "Crime": {
      "suggestions": ["Reporting a suspect", "Finding a safe place", "Self-defense tips"],
      "measures": ["Keep a safe distance", "Note suspect descriptions", "Find a well-lit area", "Stay on the line with police"]
    },
    "Generic": {
      "suggestions": ["What should I do in an emergency?", "How to help others?", "Who to call?"],
      "measures": ["Stay calm", "Assess the situation", "Call 911/Emergency", "Alert people around you"]
    }
  };

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  
  List<String> getSuggestions(String? type) {
    return _incidentData[type ?? "Generic"]?["suggestions"] ?? _incidentData["Generic"]!["suggestions"]!;
  }

  List<String> getMeasures(String? type) {
    return _incidentData[type ?? "Generic"]?["measures"] ?? _incidentData["Generic"]!["measures"]!;
  }

  // Use 10.0.2.2 for Android emulator, localhost for others
  static const String _backendUrl = 'http://10.0.2.2:5005/chatAssistant';
  // Note: For Android Emulator, change 'localhost' to '10.0.2.2' if needed.

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(
      text: text,
      type: MessageType.user,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _messages.add(ChatMessage(
          text: data['reply'] ?? "I'm sorry, I couldn't process that.",
          type: MessageType.ai,
          timestamp: DateTime.now(),
        ));
      } else {
        _messages.add(ChatMessage(
          text: "AI is currently unavailable. Please try again.",
          type: MessageType.ai,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _messages.add(ChatMessage(
        text: "AI is currently unavailable. Please try again.",
        type: MessageType.ai,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
