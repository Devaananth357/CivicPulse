import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream for auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // 1. Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if signIn() exists
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // Email Link Authentication
  Future<void> sendEmailLink(String email) async {
    var acs = ActionCodeSettings(
      url: 'https://civicpulse-dev.firebaseapp.com/__/auth/action?mode=signIn&email=$email',
      handleCodeInApp: true,
      androidPackageName: 'com.emptylife.civicpulse',
      androidInstallApp: true,
      androidMinimumVersion: '12',
    );

    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: acs,
    );
  }

  Future<UserCredential> signInWithEmailLink(String email, String emailLink) async {
    if (_auth.isSignInWithEmailLink(emailLink)) {
      return await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
    }
    throw Exception("Invalid email link");
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print("Google Sign-Out Error: $e");
    }
    await _auth.signOut();
  }

  // Email / Password Authentication
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
}
