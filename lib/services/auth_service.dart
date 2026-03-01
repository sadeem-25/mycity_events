import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; //connect to authentication
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; //connection to database

  // new user
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // document user in firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      throw e.toString();
    }
  }

  // log in
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw e.toString();
    }
  }

  // logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No logged-in user");

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) return "user";

    return doc.data()?['role'] ?? "user";
  }
}
