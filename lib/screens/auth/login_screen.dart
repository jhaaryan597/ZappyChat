import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zappychat/helper/dialogs.dart';
import 'package:zappychat/helper/theme.dart';
import 'package:zappychat/screens/home_screen.dart';

import '../../api/apis.dart';
import '../../main.dart';
//login screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _handleGoogleBtnClick() async {
    Dialogs.showProgressBar(context);
    try {
      final authResponse = await _signInWithGoogle();

      // if user is null then sign in was cancelled
      if (authResponse.user == null) {
        Navigator.pop(context);
        Dialogs.showSnackbar(context, 'Sign in cancelled!');
        return;
      }

      if (await APIs.userExists()) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        await APIs.createUser();
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      log("\n_handleGoogleBtnClick : $e");
      Dialogs.showSnackbar(context, 'Something went wrong (Check Internet!)');
    }
  }

  Future<AuthResponse> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '60256744621-050alteh2rkk4j74758j3grpf9i8qed7.apps.googleusercontent.com', // from google_services.json
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResponse();
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      return await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      log("\n_signInWithGoogle Error: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // mq = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                FadeTransition(
                  opacity: _animation,
                  child: Image.asset('images/icon.png', height: 150),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    'Welcome to ZappyChat',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    'The AI-powered messaging app',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _handleGoogleBtnClick,
                  icon: Image.asset('images/google.png', height: 24),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
