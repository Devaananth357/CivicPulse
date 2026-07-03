import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../map/map_screen.dart';
import '../home/widgets/bottom_nav.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../home/home_provider.dart';
import 'widgets/safety_notification_banner.dart';

import '../auth/providers/auth_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    // Keep HomeProvider in sync with real-time user status changes from AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.userId != null) {
        homeProvider.syncWithAuth(authProvider.userId, authProvider.userStatus);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: navProvider.currentIndex,
            children: const [
              HomeScreen(),
              HistoryScreen(),
              MapScreen(),
              AIAssistantScreen(),
            ],
          ),
          // Global Safety Banner
          Consumer<HomeProvider>(
            builder: (context, homeProvider, _) {
              final incident = homeProvider.latestIncident;
              if (incident != null && navProvider.currentIndex != 3) {
                return SafeArea(
                  child: SafetyNotificationBanner(
                    incidentType: incident.type,
                    onTap: () => navProvider.setIndex(3),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}
