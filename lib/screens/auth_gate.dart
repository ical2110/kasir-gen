import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/role_service.dart';
import '../services/session_service.dart';
import 'home_screen.dart';
import 'pending_approval_screen.dart';
import 'sign_in_screen.dart';

/// Shows the application only after Firebase has a non-anonymous user.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) return const SignInScreen();

        return _SessionGuard(user: snapshot.data!);
      },
    );
  }
}

class _SessionGuard extends StatefulWidget {
  const _SessionGuard({required this.user});

  final User user;

  @override
  State<_SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<_SessionGuard> {
  late final Future<bool> _validation;

  @override
  void initState() {
    super.initState();
    _validation = SessionService.validate(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _validation,
      builder: (context, validationSnapshot) {
        if (validationSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (validationSnapshot.data != true) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return SessionActivityTracker(
          user: widget.user,
          child: StreamBuilder<AppUser?>(
            stream: RoleService.watchCurrentUser(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (profileSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child:
                        Text('Gagal memuat profil: ${profileSnapshot.error}'),
                  ),
                );
              }

              final profile = profileSnapshot.data;
              if (profile == null || !profile.approved) {
                return const PendingApprovalScreen();
              }
              return const HomeScreen();
            },
          ),
        );
      },
    );
  }
}
