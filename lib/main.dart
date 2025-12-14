import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/Bloc/global_event.dart';
import 'package:motives_tneww/screens/new_screens/splash_screenn.dart';
import 'package:get_storage/get_storage.dart';
import 'Bloc/global_bloc.dart';

var box = GetStorage();
var email = box.read('email');
var password = box.read('password');

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Global);
}

final Global = MultiBlocProvider(
  providers: [
    email != null
        ? BlocProvider<GlobalBloc>(
            create: (_) =>
                GlobalBloc()..add(Login(email: email, password: password)),
          )
        : BlocProvider<GlobalBloc>(
            create: (_) => GlobalBloc(),
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
    print("EMAIL : $email");
    print("PASSWORD : $password");
    super.initState();

    if (email != null) {
      context.read<GlobalBloc>().add(Login(email: email, password: password));
    }
    // context
    //     .read<GlobalBloc>()
    //     .add(Login(email: email, password: password));
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    // String? token = box.read('auth_token');
    // print("Token: $token");
     var type=   box.read('type');
    return MaterialApp(
        title: 'Dr Sip',
        debugShowCheckedModeBanner: false,
        home: NewSplashScreen());
  }
}
