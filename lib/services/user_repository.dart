import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Save or update user profile
  Future<void> saveUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );
  }

  // Get user profile by uid
  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  // Real-time user updates
  Stream<AppUser?> userStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(doc.data()!) : null);
  }

  // Update specific user status with safety markers
  Future<void> updateUserStatus(String uid, String status) async {
    final bool isInDanger = status.toLowerCase() == 'danger';
    
    await _firestore.collection('users').doc(uid).update({
      'status': status,
      'isInDanger': isInDanger,
      'lastActive': FieldValue.serverTimestamp(),
      if (!isInDanger) 'lastSafeAt': FieldValue.serverTimestamp(),
    });
  }

  // Final confirmation to set user as safe
  Future<void> markUserAsSafe(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return;
      
      final data = userDoc.data()!;
      final currentStatus = (data['status'] ?? '').toString().toLowerCase();
      final bool alreadyInDanger = data['isInDanger'] == true || currentStatus == 'danger';

      // Only update if they were actually tracked as being in danger
      if (alreadyInDanger) {
        await _firestore.collection('users').doc(uid).update({
          'status': 'safe',
          'isInDanger': false,
          'lastSafeAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });
        print("🛡️ UserRepository: User $uid confirmed SAFE.");
      }
    } catch (e) {
      print("Error marking user as safe: $e");
    }
  }
}
