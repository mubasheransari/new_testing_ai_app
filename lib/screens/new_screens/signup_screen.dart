import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/widget/toast_widget.dart';
import '../../Bloc/global_bloc.dart';
import '../../Bloc/global_state.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const accent = Color(0xFFE97C42);
  final _formKey = GlobalKey<FormState>();

  bool obscurePwd = true;
  bool obscureCpwd = true;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIGNUP'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    SizedBox(
                      width: 66,
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

                // Heading + decorative shapes
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Create Account,',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('Please fill the details to continue!',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const _DecorShapes(),
                  ],
                ),

                const SizedBox(height: 28),

                // Name
                const Text('Name',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    suffixIcon: const Icon(Icons.person_outline),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),

                const SizedBox(height: 16),

                // Email
                const Text('Email',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email is required';
                    final ok =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                    return ok ? null : 'Enter a valid email';
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    suffixIcon: const Icon(Icons.mail_outline),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),

                const SizedBox(height: 16),
                const Text('Password',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePwd,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscurePwd ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscurePwd = !obscurePwd),
                    ),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Confirm Password',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureCpwd,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Confirm your password' : null,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCpwd
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscureCpwd = !obscureCpwd),
                    ),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),

                const SizedBox(height: 22),

                BlocConsumer<GlobalBloc, GlobalState>(
                  listener: (context, state) {
                    if (state.signUpStatus == SignUpStatus.success) {
                      toastWidget(
                          'User Created Successfully! Login Now', Colors.green);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NewLoginScreen()),
                      );
                    } else if (state.signUpStatus == SignUpStatus.failure) {
                      toastWidget(
                          state.errorMessageSignUp.toString(), Colors.red);
                    }
                  },
                  builder: (context, state) {
                    return Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            /*   context.read<GlobalBloc>().add(
                                  SignUp(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  ),
                                );
                            Focus.of(context).unfocus();*/
                          },
                          child: state.signUpStatus == SignUpStatus.loading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Sign Up',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
                /* SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: submit sign-up
                      }
                    },
                    child: const Text('Sign Up',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),*/

                const SizedBox(height: 22),

                // Bottom link
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewLoginScreen()),
                    );
                  },
                  child: Center(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black87, fontSize: 15),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login Now',
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
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final Widget child;
  const _CircleIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: Color(0xFFEFEFEF),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              blurRadius: 4, offset: Offset(0, 1), color: Color(0x11000000)),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// Same decorative angled blocks used on Login
class _DecorShapes extends StatelessWidget {
  const _DecorShapes();

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFFFE1D2);
    const mid = Color(0xFFF6B79C);
    const dark = Color(0xFFE97C42);

    Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: w,
          height: h,
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
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
