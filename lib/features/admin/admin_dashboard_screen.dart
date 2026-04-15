import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/incident.dart';
import '../../models/responder.dart';
import '../auth/providers/auth_provider.dart';
import 'widgets/incident_card.dart';
import 'providers/dispatch_provider.dart';
import 'widgets/dispatch_control_panel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isViewingHistory = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF020912),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF030D16), Color(0xFF020912)],
          ),
        ),
        child: Consumer<DispatchProvider>(
          builder: (context, dispatchProvider, _) {
            return StreamBuilder<List<Responder>>(
              stream: _firestoreService.getRespondersStream(),
              builder: (context, responderSnapshot) {
                return StreamBuilder<List<Incident>>(
                  stream: _isViewingHistory 
                      ? _firestoreService.getCompletedIncidentsStream() 
                      : _firestoreService.getIncidentsStream(),
                  builder: (context, incidentSnapshot) {
                    final incidents = incidentSnapshot.data ?? [];
                    final responders = responderSnapshot.data ?? [];

                    return Row(
                      children: [
                        // 1. FULL-WIDTH MAP (LEFT – PRIMARY AREA)
                        Expanded(
                          flex: 7,
                          child: Stack(
                            children: [
                              _AdminMapWidget(
                                incidents: incidents,
                                responders: responders,
                                mapController: _mapController,
                                selectedIncidentId: dispatchProvider.selectedIncident?.id,
                                onIncidentSelected: (incident) => dispatchProvider.selectIncident(incident, responders),
                              ),
                              _buildMapOverlayControls(),
                              _buildSystemStatusOverlay(),
                              _buildAdminAuthControls(authProvider),
                            ],
                          ),
                        ),

                        // 2. CENTER PANEL – COMMAND FEED
                        Container(
                          width: 360,
                          decoration: BoxDecoration(
                            color: const Color(0xFF05111D).withOpacity(0.8),
                            border: Border(
                              left: BorderSide(color: Colors.white.withOpacity(0.05)),
                              right: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildCommandHeader(),
                              _buildConfidenceIndicator(incidents),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: incidents.length,
                                  itemBuilder: (context, index) {
                                    final incident = incidents[index];
                                    return IncidentCard(
                                      incident: incident,
                                      onTap: () {
                                        dispatchProvider.selectIncident(incident, responders);
                                        if (incident.latitude != null && incident.longitude != null) {
                                          _mapController.move(
                                            LatLng(incident.latitude!, incident.longitude!),
                                            15.0,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. RIGHT PANEL – UNIT DISPATCH
                        const DispatchControlPanel(),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCommandHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isViewingHistory ? "MISSION HISTORY" : "COMMAND CENTER", 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isViewingHistory ? "COMPLETED INCIDENTS ARCHIVE" : "REAL-TIME MONITORING ACTIVE", 
                    style: TextStyle(color: _isViewingHistory ? Colors.blueAccent : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              _isViewingHistory 
                ? IconButton(
                    onPressed: () => setState(() => _isViewingHistory = false),
                    icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                  )
                : _buildLiveBadge(),
            ],
          ),
          const SizedBox(height: 20),
          // Toggle Buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleTab(
                    label: "ACTIVE FEED",
                    isSelected: !_isViewingHistory,
                    onTap: () => setState(() => _isViewingHistory = false),
                    activeColor: Colors.redAccent,
                  ),
                ),
                Expanded(
                  child: _buildToggleTab(
                    label: "COMPLETED",
                    isSelected: _isViewingHistory,
                    onTap: () => setState(() => _isViewingHistory = true),
                    activeColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({required String label, required bool isSelected, required VoidCallback onTap, required Color activeColor}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? activeColor.withOpacity(0.3) : Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const _PulseCircle(color: Colors.redAccent, size: 6),
          const SizedBox(width: 8),
          const Text("LIVE", style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(List<Incident> incidents) {
    double avgConfidence = 0;
    if (incidents.isNotEmpty) {
      avgConfidence = incidents.map((e) => e.aiConfidence).reduce((a, b) => a + b) / incidents.length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("NETWORK AI CONFIDENCE", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
              Text("${avgConfidence.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: avgConfidence / 100,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapOverlayControls() {
    return Positioned(
      top: 24,
      right: 24,
      child: Column(
        children: [
          _buildMapControlButton(Icons.add, () {
            _mapController.move(_mapController.center, _mapController.zoom + 1);
          }),
          const SizedBox(height: 8),
          _buildMapControlButton(Icons.remove, () {
            _mapController.move(_mapController.center, _mapController.zoom - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildMapControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF030D16).withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildAdminAuthControls(AuthProvider authProvider) {
    return Positioned(
      top: 24,
      left: 24,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF030D16).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
             IconButton(
                tooltip: "Add Responder",
                icon: const Icon(Icons.person_add_rounded, color: Colors.blueAccent, size: 18),
                onPressed: () => Navigator.of(context).pushNamed('/admin/add-responder'),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: "Logout Admin",
                icon: const Icon(Icons.logout_rounded, color: Colors.white38, size: 18),
                onPressed: () => authProvider.signOut(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusOverlay() {
    return Positioned(
      bottom: 24,
      left: 24,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF030D16).withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            _buildStatusItem("SIGNAL STABILITY", "99%", Colors.greenAccent),
            const SizedBox(height: 12),
            _buildStatusItem("RESCUE READINESS", "STANDBY", Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }
}

class _AdminMapWidget extends StatelessWidget {
  final List<Incident> incidents;
  final List<Responder> responders;
  final MapController mapController;
  final String? selectedIncidentId;
  final Function(Incident) onIncidentSelected;

  _AdminMapWidget({
    required this.incidents,
    required this.responders,
    required this.mapController,
    this.selectedIncidentId,
    required this.onIncidentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: const MapOptions(
        initialCenter: LatLng(12.823, 80.041), // Centered on recent activity
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.emptylife.civicpulse',
          tileBuilder: (context, tileWidget, tile) => ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -1, 0, 0, 0, 255,
              0, -1, 0, 0, 255,
              0, 0, -1, 0, 255,
              0, 0, 0, 1, 0,
            ]),
            child: tileWidget,
          ),
        ),
        
        // Incident Markers
        MarkerLayer(
          markers: incidents
              .where((i) => i.latitude != null && i.longitude != null)
              .map((incident) {
                final isSelected = incident.id == selectedIncidentId;
                final isCompleted = incident.status == 'completed';
                return Marker(
                  point: LatLng(incident.latitude!, incident.longitude!),
                  width: isSelected ? 80 : 50,
                  height: isSelected ? 80 : 50,
                  child: GestureDetector(
                    onTap: () => onIncidentSelected(incident),
                    child: _PulsingMarker(
                      color: isCompleted ? Colors.greenAccent : (incident.type.toLowerCase() == 'fire' ? Colors.redAccent : Colors.blueAccent),
                      icon: incident.type.toLowerCase() == 'fire' ? Icons.local_fire_department : Icons.medical_services,
                      isSelected: isSelected,
                      isCompleted: isCompleted,
                    ),
                  ),
                );
              }).toList(),
        ),

        // Responder Markers
        MarkerLayer(
          markers: responders
              .map((responder) {
                final color = responder.availability == 'busy' ? Colors.orangeAccent : Colors.blueAccent;
                return Marker(
                  point: LatLng(responder.latitude, responder.longitude),
                  width: 40,
                  height: 40,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                      boxShadow: [
                         BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                      ],
                    ),
                    child: Icon(Icons.person_pin_circle_rounded, color: color, size: 22),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _PulsingMarker extends StatefulWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;
  final bool isCompleted;

  const _PulsingMarker({required this.color, required this.icon, this.isSelected = false, this.isCompleted = false});

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker> with SingleTickerProviderStateMixin {
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
        return Stack(
          alignment: Alignment.center,
          children: [
            if (!widget.isCompleted)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(1 - _controller.value),
                      blurRadius: 15 * _controller.value,
                      spreadRadius: (widget.isSelected ? 20 : 10) * _controller.value,
                    ),
                  ],
                ),
              ),
            if (widget.isCompleted)
              Container(
                width: widget.isSelected ? 40 : 30,
                height: widget.isSelected ? 40 : 30,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color, width: 2),
                ),
              ),
            Icon(widget.icon, color: widget.color, size: widget.isSelected ? 32 : 24),
          ],
        );
      },
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
