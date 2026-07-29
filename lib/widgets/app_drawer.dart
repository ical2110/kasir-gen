import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kasir_gen/screens/service_management_screen.dart';
import 'package:kasir_gen/screens/account_management_screen.dart';
import 'package:kasir_gen/services/role_service.dart';
import '../screens/customer_manajement_screen.dart';
import '../screens/transaction_management_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Penting: Hapus padding dari ListView.
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Text(
              'Menu Kasir',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Halaman Utama'),
            onTap: () {
              // Aksi saat menu ditekan, misalnya menutup drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Customer'),
            onTap: () {
              // Tutup drawer terlebih dahulu
              Navigator.pop(context);
              // Navigasi ke halaman CustomerManagementScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CustomerManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_laundry_service),
            title: const Text('Layanan'),
            onTap: () {
              // Tutup drawer terlebih dahulu
              Navigator.pop(context);
              // Navigasi ke halaman ServiceManagementScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ServiceManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale),
            title: const Text('Transaksi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TransactionManagementScreen()),
              );
            },
          ),
          StreamBuilder<AppUser?>(
            stream: RoleService.watchCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.data?.isAdmin != true) {
                return const SizedBox.shrink();
              }
              return ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Verifikasi Akun'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagementScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
