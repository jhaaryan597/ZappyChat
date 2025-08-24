import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:zappychat/api/apis.dart';
import 'package:zappychat/helper/theme.dart';
import 'package:zappychat/screens/home_screen.dart';

import '../../main.dart';
import 'auth/login_screen.dart';

//splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = APIs.supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _redirect(const HomeScreen());
      } else if (event == AuthChangeEvent.signedOut) {
        _redirect(const LoginScreen());
      }
    });

    // Initial check
    final session = APIs.supabase.auth.currentSession;
    if (session != null && !session.isExpired) {
      _redirect(const HomeScreen());
    } else {
      // Failsafe: Actively sign out to clear any invalid session data
      APIs.supabase.auth.signOut(scope: SignOutScope.global);
      GoogleSignIn().signOut();
      // Adding a small delay to show splash screen
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _redirect(const LoginScreen());
      });
    }
  }

  void _redirect(Widget screen) {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'lottie/ai.json',
                width: mq.width * 0.7,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'ZappyChat',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
