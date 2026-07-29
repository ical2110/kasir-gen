import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { admin, cashier }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.approved,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool approved;

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final role = data['role'] == 'admin' ? UserRole.admin : UserRole.cashier;

    return AppUser(
      uid: document.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: role,
      // Dokumen pengguna lama dibuat sebelum fitur verifikasi. Biarkan akun
      // tersebut tetap aktif agar pembaruan ini tidak mengunci pengguna lama.
      approved: role == UserRole.admin || data['approved'] != false,
    );
  }
}

class RoleService {
  static Stream<AppUser?> watchCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((document) =>
            document.exists ? AppUser.fromDocument(document) : null);
  }

  static Future<AppUser> currentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Anda harus masuk terlebih dahulu.');
    final document =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!document.exists) {
      throw StateError('Profil akun tidak ditemukan.');
    }
    return AppUser.fromDocument(document);
  }

  static Future<UserRole> currentRole() async {
    return (await currentUser()).role;
  }

  static Future<bool> isAdmin() async => await currentRole() == UserRole.admin;
}
