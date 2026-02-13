import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Import halaman utama yang baru
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).timeout(const Duration(seconds: 15));

  if (FirebaseAuth.instance.currentUser != null) {
    return;
  }

  try {
    await FirebaseAuth.instance
        .signInAnonymously()
        .timeout(const Duration(seconds: 15));
  } on FirebaseAuthException catch (e) {
    if (e.code == 'admin-restricted-operation' ||
        e.code == 'operation-not-allowed') {
      debugPrint(
        'Anonymous auth is not enabled/restricted. Continuing without sign-in.',
      );
      return;
    }
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final Future<void> _initFuture = _initializeServices();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir Gen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal inisialisasi aplikasi:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          return const HomeScreen();
        },
      ),
    );
  }
}
