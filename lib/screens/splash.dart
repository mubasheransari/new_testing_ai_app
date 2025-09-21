import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/theme_change/theme_bloc.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Splash screen delay logic
    Timer(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreenDark()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeBloc>().state.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[300],
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.30,
          ),
          Center(
              child: Image.asset(
            'assets/logo_gym.png',
            height: 350,
            width: 350,
            // color:isDark ? Colors.white :Colors.black ,
          )),
          // SizedBox(
          //   height: MediaQuery.of(context).size.height * 0.36,
          // ),
          // ShaderMaskText(
          //     text: 'POWERED by MezanGrp'.toUpperCase(),
          //     textxfontsize: 19)
        ],
      ),
    );
  }
}
