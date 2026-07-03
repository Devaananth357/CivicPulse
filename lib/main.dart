import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'features/home/home_provider.dart';
import 'features/home/sos_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_options_screen.dart';
import 'features/navigation/navigation_provider.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'features/map/map_provider.dart';
import 'package:civic_pulse/features/emergency/emergency_provider.dart';
import 'features/ai_assistant/ai_assistant_provider.dart';

import 'firebase_options.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/admin/add_responder_screen.dart';
import 'features/admin/providers/dispatch_provider.dart';
import 'features/home/responder_home_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  print("CIVIC_PULSE: Starting main()...");
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  String? errorMessage;
  bool isNetworkError = false;

  print("CIVIC_PULSE: Initializing Firebase...");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10)); // Added timeout to catch hanging initialization
    
    firebaseInitialized = true;
    print("CIVIC_PULSE: Firebase Initialized successfully.");
  } catch (e) {
    errorMessage = e.toString();
    isNetworkError = errorMessage.contains('UnknownHostException') || 
                     errorMessage.contains('network') || 
                     errorMessage.contains('unavailable');
    print("CIVIC_PULSE: Firebase Initialization failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(initialized: firebaseInitialized)),
        ChangeNotifierProvider(create: (_) => SosProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => DispatchProvider()),
        ChangeNotifierProvider(create: (_) => AIAssistantProvider()),
        if (firebaseInitialized)
          ChangeNotifierProvider(create: (_) => HomeProvider()..initialize()),
      ],
      child: MyApp(
        firebaseInitialized: firebaseInitialized, 
        errorMessage: errorMessage,
        isNetworkError: isNetworkError,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? errorMessage;
  final bool isNetworkError;

  const MyApp({
    super.key, 
    required this.firebaseInitialized,
    this.errorMessage,
    this.isNetworkError = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Web Admin Routes
        if (settings.name == '/admin') {
          if (authProvider.status == AuthStatus.authenticated && authProvider.isAdmin) {
            return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
          }
          return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
        }

        if (settings.name == '/admin/dashboard') {
          if (authProvider.status == AuthStatus.authenticated && authProvider.isAdmin) {
            return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
          }
          // Kick back to admin login if not authorized
          return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
        }

        if (settings.name == '/admin/add-responder') {
          if (authProvider.status == AuthStatus.authenticated && authProvider.isAdmin) {
            return MaterialPageRoute(builder: (_) => const AddResponderScreen());
          }
          return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
        }

        // Standard App Routes
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/':
            return MaterialPageRoute(
              builder: (_) => firebaseInitialized 
                  ? const AuthWrapper() 
                  : _FirebaseErrorScaffold(
                      errorMessage: errorMessage,
                      isNetworkError: isNetworkError,
                    ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const AuthOptionsScreen());
        }
      },
    );
  }
}

class _FirebaseErrorScaffold extends StatelessWidget {
  final String? errorMessage;
  final bool isNetworkError;
  
  const _FirebaseErrorScaffold({
    this.errorMessage,
    this.isNetworkError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNetworkError ? Icons.wifi_off : Icons.error_outline, 
                  color: Colors.redAccent, 
                  size: 80
                ),
                const SizedBox(height: 24),
                Text(
                  isNetworkError ? "Network Connection Error" : "Firebase Initialization Failed",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  isNetworkError 
                    ? "The app cannot reach Firebase. This is usually a DNS or internet issue on your device/emulator."
                    : "The app requires a valid Firebase configuration to function.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                
                if (isNetworkError) ...[
                  const SizedBox(height: 32),
                  _buildTroubleshootingTip(
                    context, 
                    "Cold Boot Emulator", 
                    "Open Device Manager -> Action Menu (3 dots) -> Cold Boot Now."
                  ),
                  _buildTroubleshootingTip(
                    context, 
                    "Check DNS", 
                    "Ensure your host Mac has internet. Toggle Airplane mode in the emulator."
                  ),
                ],

                if (errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Technical Details:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          errorMessage!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => main(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Retry Connection", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingTip(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(description, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.status == AuthStatus.authenticating) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.status == AuthStatus.authenticated) {
      debugPrint("AuthWrapper: User is authenticated. Role: ${authProvider.userRole}");
      if (authProvider.isAdmin) {
        return const AdminDashboardScreen();
      } else if (authProvider.isResponder) {
        return const ResponderHomeScreen();
      } else {
        return const MainNavigationScreen();
      }
    }

    return const AuthOptionsScreen();
  }
}
