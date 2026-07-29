import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/role_service.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  Future<void> _editName(
    BuildContext context,
    AppUser account,
  ) async {
    var editedName = account.name;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Nama Akun'),
        content: TextFormField(
          initialValue: account.name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
          onChanged: (value) => editedName = value,
          onFieldSubmitted: (value) {
            if (value.trim().length >= 2) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = editedName.trim();
              if (value.length >= 2) Navigator.pop(dialogContext, value);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(account.uid)
          .update({'name': name});
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan nama: $error')),
      );
    }
  }

  Future<void> _setApproval(
    BuildContext context,
    String uid,
    bool approved,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'approved': approved,
        'approved_at':
            approved ? FieldValue.serverTimestamp() : FieldValue.delete(),
        'approved_by': approved
            ? FirebaseAuth.instance.currentUser!.uid
            : FieldValue.delete(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved ? 'Akun berhasil disetujui.' : 'Persetujuan akun dicabut.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui akun: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Akun')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat daftar akun: ${snapshot.error}'),
              ),
            );
          }

          final accounts = snapshot.data?.docs
                  .map(AppUser.fromDocument)
                  .toList(growable: false) ??
              const <AppUser>[];
          if (accounts.isEmpty) {
            return const Center(child: Text('Belum ada akun terdaftar.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final isCurrentAdmin = account.uid == currentUid;
              return Card(
                child: SwitchListTile(
                  secondary: Icon(
                    account.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          account.name.isEmpty
                              ? 'Nama belum tersedia'
                              : account.name,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Ubah nama',
                        onPressed: () => _editName(context, account),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    [
                      if (account.email.isNotEmpty) account.email,
                      account.isAdmin
                          ? 'Admin'
                          : account.approved
                              ? 'Kasir aktif'
                              : 'Menunggu verifikasi',
                    ].join(' • '),
                  ),
                  value: account.approved,
                  onChanged: account.isAdmin || isCurrentAdmin
                      ? null
                      : (value) => _setApproval(context, account.uid, value),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
