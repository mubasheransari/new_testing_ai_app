import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/Bloc/global_bloc.dart';
import 'package:motives_tneww/Bloc/global_event.dart';
import 'package:motives_tneww/Bloc/global_state.dart';
import 'package:motives_tneww/screens/home.dart';
import 'package:motives_tneww/theme_change/theme_bloc.dart';
import 'package:motives_tneww/theme_change/theme_event.dart';

import '../widget/gradient_button.dart';
import 'login_screen.dart';

class SignupScreenDark extends StatefulWidget {
  const SignupScreenDark({super.key});

  @override
  State<SignupScreenDark> createState() => _SignupScreenDarkState();
}

class _SignupScreenDarkState extends State<SignupScreenDark> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  //i want same design like this for profile screen including fields of Name, emloyee ID, Phone and address

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: GradientText("SIGNUP", fontSize: 24),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isDark,
              activeColor: Colors.purple,
              onChanged: (value) {
                context.read<ThemeBloc>().add(ToggleThemeEvent(value));
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[300],
          elevation: 8,
          shadowColor: isDark
              ? Colors.purple.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                    child: Image.asset(
                  'assets/logo_gym.png',
                  height: 270,
                  width: 270,
                  // color:isDark ? Colors.white :Colors.black ,
                )),
                // const SizedBox(height: 40),
                GradientText("Register Now!", fontSize: 22),
                const SizedBox(height: 20),
               
                _customTextField(
                  controller: nameController,
                  hint: "Name",
                  icon: Icons.person,

                  isDark: isDark,
                ),
                     const SizedBox(height: 16),
                _customTextField(
                  controller: emailController,
                  hint: "Email Address",
                  icon: Icons.email_outlined,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _customTextField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isDark: isDark,
                ),
            
                const SizedBox(height: 24),

                BlocConsumer<GlobalBloc, GlobalState>(
  listener: (context, state) {
    if (state.signUpStatus == SignUpStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User created successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (state.signUpStatus == SignUpStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessageSignUp ?? "Signup failed!")),
      );
    }
  },
  builder: (context, state) {
    return GradientButton(
      text: state.signUpStatus == SignUpStatus.loading ? "Loading..." : "SignUp",
      isLoading: state.signUpStatus == SignUpStatus.loading,
      onTap: state.signUpStatus == SignUpStatus.loading
          ? null
          : () {
              context.read<GlobalBloc>().add(
                SignUp(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                ),
              );
            },
    );
  },
),


// BlocConsumer<GlobalBloc, GlobalState>(
//   listener: (context, state) {
//     if (state.signUpStatus == SignUpStatus.success) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const MainScreen()),
//       );
//     } else if (state.signUpStatus == SignUpStatus.failure) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(state.errorMessageLogin.toString())),
//       );
//     }
//   },
//   builder: (context, state) {
//     return GradientButton(
//       text: state.signUpStatus == SignUpStatus.loading ? "Loading..." : "SignUp",
//       isLoading: state.signUpStatus == SignUpStatus.loading,
//       onTap: state.signUpStatus == SignUpStatus.loading
//           ? null
//           : () {
//               context.read<GlobalBloc>().add(
//                 SignUp(
//                   name: nameController.text.trim(),
//                   email: emailController.text.trim(),
//                   password: passwordController.text.trim(),
//                 ),
//               );
//             },
//     );
//   },
// ),

           
                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => LoginScreenDark()));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16),
                        ),
                        GradientText(" LOGIN", fontSize: 16),
                      ],
                    ),
                    // const Text(
                    //   "Forgot Password?",
                    //   style: TextStyle(color: Colors.cyan),
                    // ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
        prefixIcon: Icon(icon, color: Colors.cyan),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// 🔹 Gradient Text Widget
class GradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  const GradientText(this.text, {super.key, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.cyan, Colors.purpleAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
