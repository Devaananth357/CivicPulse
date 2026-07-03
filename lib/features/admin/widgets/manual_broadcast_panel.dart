import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/broadcast.dart';
import '../../../services/firestore_service.dart';

class ManualBroadcastPanel extends StatefulWidget {
  final LatLng mapCenter;

  const ManualBroadcastPanel({super.key, required this.mapCenter});

  @override
  State<ManualBroadcastPanel> createState() => _ManualBroadcastPanelState();
}

class _ManualBroadcastPanelState extends State<ManualBroadcastPanel> {
  final TextEditingController _messageController = TextEditingController();
  double _radius = 1000; // Default 1km
  bool _isSending = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _sendBroadcast() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an alert message"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final broadcast = Broadcast(
        message: _messageController.text,
        center: widget.mapCenter,
        radius: _radius,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)), // Default 2 hours
      );

      await _firestoreService.sendBroadcast(broadcast);

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚨 BROADCAST SENT SUCCESSFULLY"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send broadcast: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF030D16).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency_share_rounded, color: Colors.redAccent, size: 24),
              const SizedBox(width: 12),
              const Text(
                "MANUAL BROADCAST",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              _CoordinateChip(center: widget.mapCenter),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "ALERT MESSAGE",
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Enter the emergency message for citizens...",
              hintStyle: TextStyle(color: Colors.white10, fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "BROADCAST RADIUS",
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(_radius / 1000).toStringAsFixed(1)} KM",
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Slider(
            value: _radius,
            min: 500,
            max: 10000,
            divisions: 19,
            activeColor: Colors.redAccent,
            inactiveColor: Colors.white.withOpacity(0.05),
            onChanged: (val) => setState(() => _radius = val),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendBroadcast,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "SEND EMERGENCY ALERT",
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateChip extends StatelessWidget {
  final LatLng center;
  const _CoordinateChip({required this.center});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        "${center.latitude.toStringAsFixed(3)}, ${center.longitude.toStringAsFixed(3)}",
        style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
