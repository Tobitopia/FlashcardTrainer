import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/screens/auth/login_screen.dart';
import 'package:projects/services/auth_service.dart';
import 'package:projects/services/cloud_service.dart';
import 'package:projects/repositories/set_repository.dart';
import '../app/navigation.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isSyncing = false;
  String? _lastUserId;

  Future<void> _syncUserSets(User user) async {
    // Only sync if the user has changed (to avoid infinite loops)
    if (_lastUserId == user.uid) return;
    _lastUserId = user.uid;

    final cloudService = locator<CloudService>();
    final setRepository = locator<ISetRepository>();

    setState(() => _isSyncing = true);
    try {
      final cloudIds = await cloudService.fetchAllUserSetIds();
      final localSets = await setRepository.getAllSets();
      final localCloudIds = localSets.map((s) => s.cloudId).toSet();

      for (String id in cloudIds) {
        if (!localCloudIds.contains(id)) {
          final vocabSet = await cloudService.downloadVocabSet(id);
          if (vocabSet != null) {
            await setRepository.importSet(vocabSet);
          }
        }
      }
    } catch (e) {
      print("Background sync error: $e");
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: locator<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          
          if (user != null) {
            // Schedule the sync to run AFTER the current build frame
            if (_lastUserId != user.uid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncUserSets(user);
              });
            }
            
            if (_isSyncing) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text("Restoring your StepSets...", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8146BD))),
                    ],
                  ),
                ),
              );
            }
            return const NavigationBarScreen();
          }
          
          // User is null (logged out) - Reset tracking variable
          if (_lastUserId != null) {
             _lastUserId = null;
          }
          return const LoginScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
