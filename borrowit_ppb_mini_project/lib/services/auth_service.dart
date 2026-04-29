import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'db_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _fs = FirebaseFirestore.instance;

  static User? get firebaseUser => _auth.currentUser;

  static Future<UserModel> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = UserModel()
      ..uid = cred.user!.uid ..name = name ..email = email
      ..role = 'user' ..createdAt = DateTime.now();
    await _fs.collection('users').doc(user.uid).set({
      'uid': user.uid, 'name': name, 'email': email,
      'role': 'user', 'createdAt': user.createdAt.toIso8601String(),
    });
    await DbService.saveUser(user);
    return user;
  }

  static Future<UserModel?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;

    // SELALU ambil data terbaru dari Firestore saat login
    // agar perubahan role langsung terdeteksi
    final doc = await _fs.collection('users').doc(uid).get();
    if (doc.exists) {
      final d = doc.data()!;
      // Ambil data lokal yang sudah ada (untuk preserve id Isar)
      UserModel? existing = await DbService.getUser(uid);
      existing ??= UserModel();
      existing
        ..uid = d['uid'] ?? uid
        ..name = d['name'] ?? ''
        ..email = d['email'] ?? email
        ..role = d['role'] ?? 'user'  // <-- Role terbaru dari Firestore
        ..createdAt = DateTime.tryParse(d['createdAt'] ?? '') ?? DateTime.now();
      await DbService.saveUser(existing); // Update lokal
      return existing;
    }
    return null;
  }

  static Future<void> logout() => _auth.signOut();
}
