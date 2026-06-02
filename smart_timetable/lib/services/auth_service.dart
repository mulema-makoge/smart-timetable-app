import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      // Check admins collection first
      final adminDoc = await _db.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) return 'admin';

      // Check lecturers collection
      final lecturerDoc = await _db.collection('lecturers').doc(user.uid).get();
      if (lecturerDoc.exists) return 'lecturer';

      return null;
    } catch (e) {
      return null;
    }
  }
}
