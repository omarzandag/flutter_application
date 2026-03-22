import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create user object based on Firebase User
  User? get currentUser => _auth.currentUser;

  // Auth change user stream
  Stream<User?> get user => _auth.authStateChanges();

  // Register with email & password
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        final db = FirebaseDatabase.instance.ref().child('users').child(result.user!.uid);
        await db.child('profile').set({
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
        });
        // Immediately sign the user out to require a manual login
        await _auth.signOut();
      }
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign in with email & password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Change Password
  Future<void> changePassword(String newPassword) async {
    try {
      if (currentUser != null) {
        await currentUser!.updatePassword(newPassword);
      } else {
        throw 'No user is currently signed in.';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
