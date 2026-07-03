import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/status_header.dart';
import 'widgets/sos_map.dart';
import 'widgets/alert_card.dart';
import 'widgets/info_card.dart';
import 'widgets/sos_section.dart';
import 'widgets/responder_tracker_card.dart';
import 'widgets/verification_overlay.dart';
import 'widgets/broadcast_alert_overlay.dart';
import 'widgets/aqi_dashboard_box.dart';
import 'home_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final isDanger = homeProvider.effectiveStatus.toLowerCase() == 'danger';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background "Danger" Glow
          if (isDanger)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.redAccent.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                StatusHeader(systemStatus: homeProvider.systemStatus),
                
                // High-Alert Banner
                if (isDanger)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.redAccent.withOpacity(0.1),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "HIGH ALERT: ACTIVE EMERGENCY IN YOUR AREA",
                            style: TextStyle(
                              color: Colors.redAccent.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await homeProvider.fetchSystemStatus();
                      await homeProvider.fetchRespondersCount();
                      await homeProvider.fetchAirQuality();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        children: [
                          if (homeProvider.isLoading)
                            const LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              color: AppColors.primary,
                            ),
                          SosMap(
                            height: 350,
                            activeIncident: homeProvider.latestIncident,
                          ),
                          const SizedBox(height: 16),
                          const SOSSection(),
                          const SizedBox(height: 16),
                          ResponderTrackerCard(incident: homeProvider.latestIncident),
                          const SizedBox(height: 16),
                          AlertCard(incident: homeProvider.latestIncident),
                          const SizedBox(height: 16),
                          // New Standalone AQI Box
                          AqiDashboardBox(airQuality: homeProvider.airQuality),
                          const SizedBox(height: 16),
                          const InfoCard(
                            title: 'Safety Tip of the Day',
                            subtitle: 'Keep a portable power bank charged for emergencies.',
                            icon: Icons.lightbulb_rounded,
                            iconColor: Colors.amber,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (homeProvider.verifiableIncidents.isNotEmpty)
            VerificationOverlay(incident: homeProvider.verifiableIncidents.first),
            
          if (homeProvider.activeBroadcast != null)
            BroadcastAlertOverlay(
              broadcast: homeProvider.activeBroadcast!,
              onDismiss: () => homeProvider.dismissBroadcast(),
            ),
        ],
      ),
    );
  }
}
