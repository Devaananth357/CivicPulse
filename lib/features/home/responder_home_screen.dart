import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/responder_provider.dart';
import 'screens/responder_alert_screen.dart';
import 'screens/chat_screen.dart';
import 'responder_main_screen.dart';

class ResponderHomeScreen extends StatelessWidget {
  const ResponderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final uid = authProvider.appUser?.uid ?? '';

    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF030D16),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ResponderProvider(uid: uid),
      child: Consumer<ResponderProvider>(
        builder: (context, provider, _) {
          final responder = provider.currentResponder;
          final incident = provider.assignedIncident;

          // 1. Loading State: If we know an incident is assigned but it's still loading, show a spinner
          if (responder?.assignedIncidentId != null && (provider.isLoadingIncident || incident == null)) {
            return const Scaffold(
              backgroundColor: Color(0xFF030D16),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 24),
                    Text(
                      "RECEIVING OPERATIONAL DATA...",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            );
          }

          // 2. Alert State: If a new incident is assigned but NOT YET ACCEPTED (still 'available'), show the Alert Screen
          if (responder?.assignedIncidentId != null && responder?.availability == 'available') {
            return const ResponderAlertScreen();
          }

          // 3. Main State: Otherwise, show the main navigation shell (Hub/Map/Profile)
          return const ResponderMainScreen();
        },
      ),
    );
  }
}

class ResponderHomeScreenContent extends StatelessWidget {
  const ResponderHomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ResponderProvider>(context);
    final responder = provider.currentResponder;
    final activeIncident = responder?.assignedIncidentId != null && 
        (provider.assignedIncident?.status == 'in_progress' || provider.assignedIncident?.status == 'assigned')
        ? provider.assignedIncident 
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF030D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "RESPONDER HUB",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (activeIncident != null) ...[
                    _buildActiveMissionCard(context, activeIncident),
                    const SizedBox(height: 24),
                  ],
                  _buildStatusCard(
                    title: "DUTY STATUS",
                    value: responder?.availability.toUpperCase() ?? "OFFLINE",
                    icon: Icons.shield_rounded,
                    color: responder?.availability == 'available' ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(height: 20),
                  _buildStatusCard(
                    title: "SPECIALIZATION",
                    value: responder?.specialization.toUpperCase() ?? "GENERAL",
                    icon: Icons.badge_rounded,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "MISSION CONTROL",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildScanningCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMissionCard(BuildContext context, dynamic incident) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ACTIVE MISSION", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            incident.type.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(incident.location, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Provider.of<ResponderProvider>(context, listen: false).setTabIndex(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("VIEW ON MAP", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
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
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text("CHAT WITH REPORTER", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanningCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.radar_rounded, size: 48, color: Colors.blueAccent.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            "SCANNING FOR INCIDENTS",
            style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            "You will be notified immediately when a mission is assigned.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white10, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
