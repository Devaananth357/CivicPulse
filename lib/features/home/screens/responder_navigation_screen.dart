import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/responder_provider.dart';
import '../../../models/incident.dart';
import '../../../core/utils/map_utils.dart';
import 'chat_screen.dart';

class ResponderNavigationScreen extends StatefulWidget {
  const ResponderNavigationScreen({super.key});

  @override
  State<ResponderNavigationScreen> createState() => _ResponderNavigationScreenState();
}

class _ResponderNavigationScreenState extends State<ResponderNavigationScreen> {
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
    final responder = provider.currentResponder;
    final incident = provider.assignedIncident;

    // Use responder location or fallback to incident center
    final initialLat = responder?.latitude ?? incident?.latitude ?? 12.823;
    final initialLng = responder?.longitude ?? incident?.longitude ?? 80.041;

    return Scaffold(
      backgroundColor: const Color(0xFF030D16),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(initialLat, initialLng),
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

              // Incident Marker (Target)
              if (incident != null && incident.latitude != null && incident.longitude != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(incident.latitude!, incident.longitude!),
                      width: 80,
                      height: 80,
                      child: _buildIncidentMarker(incident.type),
                    ),
                  ],
                ),

              // Responder Marker (Self)
              if (responder != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(responder.latitude, responder.longitude),
                      width: 50,
                      height: 50,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                        child: const Icon(Icons.navigation_rounded, color: Colors.blueAccent, size: 24),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top Info Overlay
          if (incident != null)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1D2A).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_rounded, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("NAVIGATING TO MISSION", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            incident.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("4m ETA", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          
          // 3. Floating Controls & Action HUD
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Map Navigation Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMapControl(Icons.my_location_rounded, () {}),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Mission Action Panel
                if (incident != null)
                  _buildMissionActionHUD(context, provider, incident),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionActionHUD(BuildContext context, ResponderProvider provider, Incident incident) {
    final isPending = incident.status == 'completion_pending';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D2A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPending ? Colors.orangeAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPending ? "CLOSURE REQUESTED" : "MISSION IN PROGRESS",
                    style: TextStyle(
                      color: isPending ? Colors.orangeAccent : Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text("ON-SITE OPERATIONAL PHASE", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              if (isPending)
                const _PulseCircle(color: Colors.orangeAccent, size: 8)
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blueAccent, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              incidentId: incident.id!,
                              otherPartyName: incident.reporterName ?? 'Reporter',
                            ),
                          ),
                        );
                      },
                    ),
                    const _PulseCircle(color: Colors.blueAccent, size: 8),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isPending ? null : () => _showRequestConfirm(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? Colors.white.withOpacity(0.05) : Colors.blueAccent,
                foregroundColor: isPending ? Colors.white38 : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: isPending ? 0 : 8,
                shadowColor: Colors.blueAccent.withOpacity(0.5),
              ),
              child: Text(
                isPending ? "WAITING FOR ADMIN REVIEW" : "REQUEST MISSION COMPLETION",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isPending)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showBackupDialog(context, provider),
                icon: const Icon(Icons.group_add_rounded, size: 18),
                label: const Text("REQUEST ADDITIONAL BACKUP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, ResponderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1D2A),
        title: const Text("Select Backup Team", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBackupOption(context, provider, "Medic", Icons.medical_services_rounded, Colors.blueAccent),
            _buildBackupOption(context, provider, "Fire", Icons.local_fire_department_rounded, Colors.redAccent),
            _buildBackupOption(context, provider, "Police", Icons.local_police_rounded, Colors.indigoAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupOption(BuildContext context, ResponderProvider provider, String type, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(type, style: const TextStyle(color: Colors.white)),
      onTap: () {
        provider.requestBackup(type);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Backup request for $type sent to Command Center"),
            backgroundColor: Colors.blueAccent,
          ),
        );
      },
    );
  }

  void _showRequestConfirm(BuildContext context, ResponderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1D2A),
        title: const Text("Request Completion?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "This will notify the Admin that you have finished the mission. You must wait for their final approval to be marked as available again.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              provider.requestCompletion();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("NOTIFY ADMIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1D2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white70, size: 24),
      ),
    );
  }

  Widget _buildIncidentMarker(String type) {
    final color = type.toLowerCase() == 'fire' ? Colors.redAccent : Colors.blueAccent;
    return Stack(
      alignment: Alignment.center,
      children: [
        _PulsingRing(color: color),
        Icon(Icons.location_on_rounded, color: color, size: 40),
      ],
    );
  }
}

class _PulseCircle extends StatefulWidget {
  final Color color;
  final double size;

  const _PulseCircle({required this.color, required this.size});

  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  final Color color;
  const _PulsingRing({required this.color});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60 * _controller.value,
          height: 60 * _controller.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color.withOpacity(1 - _controller.value), width: 2),
          ),
        );
      },
    );
  }
}
