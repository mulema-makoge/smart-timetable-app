import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get currently logged in user
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get role of currently logged in user from Firestore
  Future<String?> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      debugPrint('Checking role for: ${user.email} | UID: ${user.uid}');

      final adminDoc =
          await _db.collection('admins').doc(user.uid).get();
      debugPrint('Admin doc exists: ${adminDoc.exists}');
      if (adminDoc.exists) return 'admin';

      final lecturerSnap = await _db
          .collection('lecturers')
          .where('email', isEqualTo: user.email)
          .get();
      debugPrint('Lecturer docs found: ${lecturerSnap.docs.length}');
      if (lecturerSnap.docs.isNotEmpty) return 'lecturer';

      return null;
    } catch (e) {
      debugPrint('getUserRole error: $e');
      return null;
    }
  }
}