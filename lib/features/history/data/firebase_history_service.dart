import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseHistoryService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  Future<void> saveHistory({
    required String label,
    required double confidence,
    String? imageUrl,
  }) async {
    await _db.collection('users').doc(uid).collection('histories').add({
      'label': label,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getHistoryStream() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('histories')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
