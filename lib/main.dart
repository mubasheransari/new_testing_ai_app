import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motives_tneww/Bloc/global_event.dart';
import 'package:motives_tneww/screens/home.dart';
import 'package:motives_tneww/screens/new_screens/home_screen.dart';
import 'package:motives_tneww/screens/new_screens/login_screen.dart';
import 'package:motives_tneww/screens/new_screens/splash_screenn.dart';
import 'package:motives_tneww/screens/splash.dart';
import 'package:motives_tneww/theme_change/theme_bloc.dart';
import 'package:motives_tneww/theme_change/theme_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_storage/get_storage.dart';
import 'Bloc/global_bloc.dart';
//        applicationId "com.example.motives_android_conversion_new"

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Global);
}

final Global = MultiBlocProvider(
  providers: [
    BlocProvider<ThemeBloc>(
      create: (_) => ThemeBloc(),
    ),
    BlocProvider<GlobalBloc>(
      create: (_) => GlobalBloc()
        ..add(Login(email: 'hassamullah066@gmail.com', password: 'admin@123')),
    ),
  ],
  child: const MyApp(),
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context
        .read<GlobalBloc>()
        .add(Login(email: 'hassamullah066@gmail.com', password: 'admin@123'));
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    String? token = box.read('auth_token');
    print("Token: $token");
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
            title: 'Dr Sip',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              //colorScheme: ColorScheme.fromSeed(seedColor: accent),
              useMaterial3: true,
              textTheme: const TextTheme(
                headlineMedium:
                    TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                bodyMedium: TextStyle(fontSize: 15, color: Colors.black54),
                labelLarge:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            // theme: ThemeData(
            //   brightness: Brightness.light,
            //   primarySwatch: Colors.blue,
            //   scaffoldBackgroundColor: Colors.white,
            //   textTheme: const TextTheme(
            //     bodyLarge: TextStyle(color: Colors.black),
            //     bodyMedium: TextStyle(color: Colors.black),
            //     bodySmall: TextStyle(color: Colors.black),
            //   ),
            // ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
                bodySmall: TextStyle(color: Colors.white),
              ),
            ),
            themeMode: state.themeMode,
            home:
                token != null ? RootTabs() : NewSplashScreen() //SplashScreen(),
            );
      },
    );
  }
}


// void main() {
//     WidgetsFlutterBinding.ensureInitialized();
  // runApp(
  //   BlocProvider(
  //     create: (_) => ThemeBloc(),
  //     child: const MyApp(),
  //   ),
  // );
// }



// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ThemeBloc, ThemeState>(
//       builder: (context, state) {
//         return MaterialApp(
//           title: 'Motives-T',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             brightness: Brightness.light,
//             primarySwatch: Colors.blue,
//             scaffoldBackgroundColor: Colors.white,
//             textTheme: const TextTheme(
//               bodyLarge: TextStyle(color: Colors.black),
//               bodyMedium: TextStyle(color: Colors.black),
//               bodySmall: TextStyle(color: Colors.black),
//             ),
//           ),
//           darkTheme: ThemeData(
//             brightness: Brightness.dark,
//             scaffoldBackgroundColor: Colors.black,
//             textTheme: const TextTheme(
//               bodyLarge: TextStyle(color: Colors.white),
//               bodyMedium: TextStyle(color: Colors.white),
//               bodySmall: TextStyle(color: Colors.white),
//             ),
//           ),
//           themeMode: state.themeMode,
//           home: SplashScreen(),
//         );
//       },
//     );
//   }
// }



// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ThemeBloc, ThemeState>(
//       builder: (context, state) {
//         return MaterialApp(
//           title: 'Motives-T',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData.light(),
//           darkTheme: ThemeData.dark(),
//           themeMode: state.themeMode,
//           home: const MainScreen(),
//         );
//       },
//     );
//   }
// }
