import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// ===============================
  /// Register with Email & Password
  /// ===============================
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String location,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'location': location,
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return uid;
    } on FirebaseAuthException catch (e) {
      return Future.error(e.message ?? 'Register failed');
    }
  }

  /// ===============================
  /// Login with Email & Password
  /// ===============================
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user?.uid;
    } on FirebaseAuthException catch (e) {
      return Future.error(e.message ?? 'Login failed');
    }
  }

  /// ===============================
  /// SIGN IN WITH GOOGLE
  /// ===============================
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        // user cancel login
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await _auth.signInWithCredential(credential);

      final user = userCred.user;
      if (user == null) return null;

      final userDoc = _db.collection('users').doc(user.uid);

      // 🔑 simpan ke firestore hanya jika user baru
      if (userCred.additionalUserInfo?.isNewUser == true) {
        await userDoc.set({
          'name': user.displayName ?? '',
          'email': user.email,
          'location': '', // bisa diisi nanti
          'photoUrl': user.photoURL,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user.uid;
    } on FirebaseAuthException catch (e) {
      return Future.error(e.message ?? 'Google sign-in failed');
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// ===============================
  /// Logout
  /// ===============================
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// ===============================
  /// Current User
  /// ===============================
  User? get currentUser => _auth.currentUser;
}
