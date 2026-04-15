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

void main() async {
  print("CIVIC_PULSE: Starting main()...");
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  String? errorMessage;

  print("CIVIC_PULSE: Initializing Firebase...");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print("CIVIC_PULSE: Firebase Initialized successfully.");
  } catch (e) {
    errorMessage = e.toString();
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
      child: MyApp(firebaseInitialized: firebaseInitialized, errorMessage: errorMessage),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? errorMessage;

  const MyApp({
    super.key, 
    required this.firebaseInitialized,
    this.errorMessage,
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
      initialRoute: '/',
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
          case '/':
            return MaterialPageRoute(
              builder: (_) => firebaseInitialized 
                  ? const AuthWrapper() 
                  : _FirebaseErrorScaffold(errorMessage: errorMessage),
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
  const _FirebaseErrorScaffold({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Firebase Configuration Missing",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "The app requires Firebase to function. "
                "Please ensure you have added GoogleService-Info.plist (iOS) "
                "or google-services.json (Android).",
                textAlign: TextAlign.center,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
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
