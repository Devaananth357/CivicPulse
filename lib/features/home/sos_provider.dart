import 'package:flutter/material.dart';
import '../../services/sos_service.dart';

class SosProvider extends ChangeNotifier {
  final SosService _sosService = SosService();

  bool _isSending = false;
  bool get isSending => _isSending;

  Future<void> sendSOS(String userId) async {
    if (_isSending) return;

    _isSending = true;
    notifyListeners();

    try {
      await _sosService.triggerSOS(userId);
      print("SOS Alert: Broadcast sent correctly for user $userId");
    } catch (e) {
      print("SosProvider Error: $e");
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
