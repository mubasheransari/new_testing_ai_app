import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_tneww/screens/new_screens/doctors_screen.dart';
import 'package:motives_tneww/screens/new_screens/home_screen.dart';
import 'package:motives_tneww/screens/new_screens/signup_screen.dart';
import 'package:motives_tneww/widget/toast_widget.dart';
import '../../Bloc/global_bloc.dart';
import '../../Bloc/global_event.dart';
import '../../Bloc/global_state.dart';
import 'forget_password.dart';

var box = GetStorage();

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({super.key});

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends State<NewLoginScreen> {
  bool rememberMe = true;
  bool obscure = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE97C42);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back,',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text('Hello there, sign in to continue!',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const _DecorShapes(),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Email',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    suffixIcon: const Icon(Icons.mail_outline),
                    enabledBorder: border,
                    focusedBorder: border,
                    hintText: 'Jacob_jones4@gmail.com'),
              ),
              const SizedBox(height: 18),
              const Text('Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: '********',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon:
                        Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  ),
                  enabledBorder: border,
                  focusedBorder: border,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NewForgotPasswordScreen()));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              BlocConsumer<GlobalBloc, GlobalState>(
                listener: (context, state) {
                  if (state.loginStatus == LoginStatus.success) {
                    box.write('email', emailController.text.trim());
                    box.write('password', passwordController.text.trim());
                    toastWidget('Login Successfully!', Colors.green);
                    if(state.loginModel!.user.customerType == 1){
  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const RootTabs()),
                      (Route<dynamic> route) => false, // remove everything
                    );
                    }
                    else{
                        Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
                      (Route<dynamic> route) => false, // remove everything
                    );
                    }//Testing@123

                    // Navigator.of(context).pushAndRemoveUntil(
                    //   MaterialPageRoute(builder: (_) => const RootTabs()),
                    //   (Route<dynamic> route) => false, // remove everything
                    // );

                    // Navigator.push(context,
                    //     MaterialPageRoute(builder: (context) => RootTabs()));
                  } else if (state.loginStatus == LoginStatus.failure) {
                    toastWidget('Login failed! Please try again.', Colors.red);
                  }
                },
                builder: (context, state) {
                  return Center(
                    child: SizedBox(
                      width: double
                          .infinity, //MediaQuery.of(context).size.width * 0.40,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          context.read<GlobalBloc>().add(
                                Login(
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                ),
                              );
                        },
                        child: state.loginStatus == LoginStatus.loading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Text('Login',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SignupScreen()));
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black87, fontSize: 15),
                      children: [
                        TextSpan(text: 'New User? '),
                        TextSpan(
                          text: 'Register Now',
                          style: TextStyle(
                              color: accent, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _CircleIcon({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 1),
              color: Color(0x11000000),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Top-right decorative peach angled rectangles to match the mock.
/// Pure Flutter, no assets.
class _DecorShapes extends StatelessWidget {
  const _DecorShapes();

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFFFE1D2);
    const mid = Color(0xFFF6B79C);
    const dark = Color(0xFFE97C42);

    Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
      return Transform.rotate(
        angle: angle, // ~34°
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return SizedBox(
      width: 110,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -6, top: 0, child: block(light)),
          Positioned(right: 6, top: 22, child: block(mid, w: 78)),
          Positioned(right: -12, top: 48, child: block(dark, w: 64, h: 22)),
        ],
      ),
    );
  }
}
