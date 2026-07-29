import 'package:flutter/material.dart';

import '../services/session_service.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menunggu Verifikasi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Akun belum disetujui admin',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin perlu memverifikasi akun ini sebelum Anda dapat '
                  'mengakses data kasir. Halaman akan terbuka otomatis setelah '
                  'akun disetujui.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: SessionService.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
