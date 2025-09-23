import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_tneww/screens/new_screens/home_screen.dart';
import 'onboarding_screen.dart';

class NewSplashScreen extends StatefulWidget {
  const NewSplashScreen({super.key});

  @override
  State<NewSplashScreen> createState() => _NewSplashScreenState();
}

class _NewSplashScreenState extends State<NewSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
    ..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    var box = GetStorage();
    String? token = box.read('auth_token');
    print("Token: $token");
    Timer(const Duration(seconds: 3), () {
      if (token != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => RootTabs()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
          (route) => false,
        );
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: Colors.black87,
    );
    const footerStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo + Title
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Replace with your exact logo asset
                  //  — keep transparent PNG/SVG sized ~160x120 for sharpness
                  Center(
                    child: SizedBox(
                      width: 360,
                      height: 320,
                      child: Image.asset(
                        'assets/logo_gym.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 12),
                  // const Text('DR. SIP', style: titleStyle),
                ],
              ),
              const Spacer(flex: 3),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text('@Dr.Sip 2025',
                      style: footerStyle.copyWith(color: Color(0xFFE97C42))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
