import 'package:flutter/material.dart';
import '../../../models/incident.dart';
import '../../../models/broadcast.dart';
import '../../../services/firestore_service.dart';
import 'package:latlong2/latlong.dart';

class SmartBroadcastDialog extends StatefulWidget {
  final Incident incident;

  const SmartBroadcastDialog({super.key, required this.incident});

  @override
  State<SmartBroadcastDialog> createState() => _SmartBroadcastDialogState();
}

class _SmartBroadcastDialogState extends State<SmartBroadcastDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _showForm = false;
  final TextEditingController _messageController = TextEditingController();
  double _radius = 2000; // Default 2km
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = "Emergency reported in your area (${widget.incident.type}). Please avoid this location.";
  }

  Future<void> _sendBroadcast() async {
    if (widget.incident.latitude == null || widget.incident.longitude == null) return;

    setState(() => _isSending = true);
    print("🚨 SmartBroadcastDialog: Sending alert for reporter: ${widget.incident.userId}");
    try {
      final broadcast = Broadcast(
        message: _messageController.text,
        center: LatLng(widget.incident.latitude!, widget.incident.longitude!),
        radius: _radius,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        excludeUserId: widget.incident.userId,
        incidentId: widget.incident.id,
      );

      await _firestoreService.sendBroadcast(broadcast);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: const Color(0xFF030D16).withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _showForm ? _buildForm() : _buildPrompt(),
          ),
        ),
      ),
    );
  }

  Widget _buildPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emergency_share_rounded, color: Colors.redAccent, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          "INCIDENT ASSIGNED",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "A responder has been dispatched to the ${widget.incident.type} incident. Do you want to alert nearby users about this situation?",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.white24,
                ),
                child: const Text("IGNORE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _showForm = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("SEND ALERT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 12),
            const Text(
              "BROADCAST DETAILS",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _showForm = false),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white38, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "MESSAGE",
          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "RADIUS",
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              "${(_radius / 1000).toStringAsFixed(1)} KM",
              style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        Slider(
          value: _radius,
          min: 500,
          max: 10000,
          divisions: 19,
          activeColor: Colors.blueAccent,
          inactiveColor: Colors.white.withOpacity(0.05),
          onChanged: (val) => setState(() => _radius = val),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBroadcast,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSending
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("INITIALIZE BROADCAST", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
        ),
      ],
    );
  }
}
