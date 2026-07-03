import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/responder_provider.dart';
import '../../../core/utils/map_utils.dart';
import '../../../core/theme/app_colors.dart';

class ResponderAlertScreen extends StatefulWidget {
  const ResponderAlertScreen({super.key});

  @override
  State<ResponderAlertScreen> createState() => _ResponderAlertScreenState();
}

class _ResponderAlertScreenState extends State<ResponderAlertScreen> {
  late final NetworkTileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = NetworkTileProvider(
      httpClient: MapUtils.mapClient,
      headers: {
        'User-Agent': 'CivicPulse/1.0 (com.emptylife.civicpulse; contact@civicpulse.app)',
        'Accept': 'image/png,image/*',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ResponderProvider>(context);
    final incident = provider.assignedIncident;

    if (incident == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF030D16),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1D2A), Color(0xFF030D16)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildIncidentSummary(incident),
                        const SizedBox(height: 24),
                        _buildAIInfo(incident),
                        const SizedBox(height: 24),
                        _buildRequirements(incident),
                        const SizedBox(height: 24),
                        _buildMapPreview(context, incident),
                        const SizedBox(height: 100), // Buffer for buttons
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          _buildActionButtons(context, provider),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "CRITICAL ALERT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "NEW ALERT",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentSummary(dynamic incident) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "${_getIcon(incident.type)} ${incident.type.toUpperCase()}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              _buildBadge("LVL 1", Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            incident.location,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInfo(dynamic incident) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoBox(
            "AI VERIFIED",
            "${incident.aiConfidence}%",
            Icons.verified_user,
            Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoBox(
            "ESCALATION",
            "HIGH",
            Icons.trending_up,
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirements(dynamic incident) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SEVERITY", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(incident.severity.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("REQUIRED UNITS", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Engine X, Ladder X", style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(BuildContext context, dynamic incident) {
    final lat = incident.latitude ?? 0.0;
    final lng = incident.longitude ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("LOCATION PREVIEW", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            const Text("ETA: 4 MINS", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 15,
              ),
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    0, 0, 0, 1, 0,
                  ]),
                  child: TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.emptylife.civicpulse',
                    maxZoom: 18,
                    tileProvider: _tileProvider,
                    fallbackUrl: 'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                    errorTileCallback: (tile, error, stackTrace) {
                      debugPrint('[MAP] Tile error: ${tile.coordinates} - $error');
                    },
                    tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 200)),
                    retinaMode: false,
                  ),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ResponderProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, const Color(0xFF030D16).withOpacity(0.9)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => provider.acceptMission(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 12,
                  shadowColor: Colors.greenAccent.withOpacity(0.4),
                ),
                child: const Text("ACCEPT MISSION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => provider.rejectMission(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return '🔥';
      case 'medical': return '🚑';
      case 'accident': return '🚗';
      case 'crime': return '👮';
      default: return '🚨';
    }
  }
}
