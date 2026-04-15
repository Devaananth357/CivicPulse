import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/status_header.dart';
import 'widgets/sos_map.dart';
import 'widgets/alert_card.dart';
import 'widgets/info_card.dart';
import 'widgets/sos_section.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/responder_tracker_card.dart';
import 'home_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StatusHeader(systemStatus: homeProvider.systemStatus),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await homeProvider.fetchSystemStatus();
                  await homeProvider.fetchRespondersCount();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()
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
                      ResponderTrackerCard(incident: homeProvider.latestIncident),
                      const SizedBox(height: 16),
                      AlertCard(incident: homeProvider.latestIncident),
                      const SizedBox(height: 16),
                      const InfoCard(
                        title: 'Safety Tip of the Day',
                        subtitle: 'Keep a portable power bank charged for emergencies.',
                        icon: Icons.lightbulb_rounded,
                        iconColor: Colors.amber,
                      ),
                      const InfoCard(
                        title: 'Current Air Quality',
                        subtitle: 'AQI: 42 (Good) — Safe for outdoor activities.',
                        icon: Icons.air_rounded,
                        iconColor: Colors.cyan,
                      ),
                      const SizedBox(height: 24),
                      const SOSSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
