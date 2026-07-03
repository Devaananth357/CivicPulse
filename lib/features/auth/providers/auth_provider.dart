import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_repository.dart';

enum AuthStatus { authenticated, unauthenticated, authenticating }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

  AppUser? _appUser;
  AuthStatus _status = AuthStatus.unauthenticated;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<AppUser?>? _userSubscription;

  AppUser? get appUser => _appUser;
  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.authenticating;

  bool get isAdmin => _appUser?.role == 'admin';
  bool get isResponder => _appUser?.role == 'responder';
  String? get userId => _appUser?.uid;
  String? get userName => _appUser?.displayName;
  String get userRole => _appUser?.role ?? 'user';
  String get userStatus => _appUser?.status ?? 'safe';

  AuthProvider({bool initialized = true}) {
    if (initialized) {
      _init();
    } else {
      _status = AuthStatus.unauthenticated;
    }
  }

  void _init() {
    _status = AuthStatus.authenticating;
    
    _authSubscription = _authService.user.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _appUser = null;
        _userSubscription?.cancel();
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else {
        await _signInSync(firebaseUser);
      }
    });
  }

  Future<void> _signInSync(User firebaseUser) async {
    // 1. Fetch from 'users' collection once for initial role check
    _appUser = await _userRepository.getUser(firebaseUser.uid);
    
    // 2. Check for role in 'responders' collection as a fallback/sync mechanism
    String resolvedRole = _appUser?.role ?? 'user';
    
    if (resolvedRole == 'user') {
      final responderDoc = await FirebaseFirestore.instance
          .collection('responders')
          .doc(firebaseUser.uid)
          .get();
      
      if (responderDoc.exists) {
        resolvedRole = 'responder';
      }
    }

    if (_appUser == null) {
      // Create new profile
      _appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        phoneNumber: firebaseUser.phoneNumber,
        photoUrl: firebaseUser.photoURL,
        role: resolvedRole,
        lastActive: DateTime.now(),
      );
      await _userRepository.saveUser(_appUser!);
    }

    // 3. Start Real-time listener for the user profile (status, role, etc)
    _userSubscription?.cancel();
    _userSubscription = _userRepository.userStream(firebaseUser.uid).listen((updatedUser) {
      if (updatedUser != null) {
        _appUser = updatedUser;
        notifyListeners();
      }
    });
    
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // Update specific user status
  Future<void> updateStatus(String status) async {
    if (_appUser == null) return;
    await _userRepository.updateUserStatus(_appUser!.uid, status);
  }

  // Google Sign-In wrapper
  Future<void> signInWithGoogle() async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  
  // Email Link Auth wrappers
  Future<void> sendEmailLink(String email) async {
    await _authService.sendEmailLink(email);
  }

  Future<void> signInWithEmailLink(String email, String link) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _authService.signInWithEmailLink(email, link);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _userSubscription?.cancel();
    await _authService.signOut();
  }

  // General Auth (Responders & Users)
  Future<void> signIn(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final credential = await _authService.signInWithEmailAndPassword(email, password);
      if (credential.user != null) {
        await _signInSync(credential.user!);
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final credential = await _authService.signUpWithEmailAndPassword(email, password);
      final user = credential.user;
      
      if (user != null) {
        // Update Firebase Auth Display Name
        await user.updateDisplayName(name);
        
        // Initial Firestore Sync
        _appUser = AppUser(
          uid: user.uid,
          email: email,
          displayName: name,
          role: 'user', // Default for self-signup
          lastActive: DateTime.now(),
        );
        await _userRepository.saveUser(_appUser!);
        await _signInSync(user);
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Admin Specific Auth
  Future<void> signInAsAdmin(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final credential = await _authService.signInWithEmailAndPassword(email, password);
      final user = credential.user;
      
      if (user != null) {
        // EXPLICITLY wait for sync before checking role
        await _signInSync(user);
        
        if (!isAdmin) {
          await signOut();
          _appUser = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          throw Exception("Unauthorized access: Not an administrator.");
        }
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
