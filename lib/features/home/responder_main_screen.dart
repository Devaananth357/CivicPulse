import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'responder_home_screen.dart';
import 'screens/responder_navigation_screen.dart';
import 'screens/responder_profile_screen.dart';
import 'providers/responder_provider.dart';

class ResponderMainScreen extends StatefulWidget {
  const ResponderMainScreen({super.key});

  @override
  State<ResponderMainScreen> createState() => _ResponderMainScreenState();
}

class _ResponderMainScreenState extends State<ResponderMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ResponderHomeScreenContent(),
    const ResponderNavigationScreen(),
    const ResponderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ResponderProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030D16),
      body: IndexedStack(
        index: provider.currentTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1D2A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: provider.currentTabIndex,
          onTap: (index) => provider.setTabIndex(index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "HOME",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.navigation_rounded),
              label: "MAP",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "PROFILE",
            ),
          ],
        ),
      ),
    );
  }
}
