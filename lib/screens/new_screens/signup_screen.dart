import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/widget/toast_widget.dart';
import '../../Bloc/global_bloc.dart';
import '../../Bloc/global_event.dart';
import '../../Bloc/global_state.dart';
import 'login_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// TODO: update these imports based on your project
// import 'your_global_bloc.dart';
// import 'new_login_screen.dart';
// import 'toast.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const accent = Color(0xFFE97C42);
  static const fieldBg = Color(0xFFF4F5F7);

  final _formKey = GlobalKey<FormState>();

  bool obscurePwd = true;
  bool obscureCpwd = true;

  // 1 = Individual, 2 = Professional
  int _userType = 1;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _passwordValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Min 6 characters';
    return null;
  }

  String? _confirmPasswordValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Confirm your password';
    if (value != passwordController.text.trim()) return 'Passwords do not match';
    return null;
  }

  void _submit(BuildContext context) {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // _userType -> 1 (Individual) or 2 (Professional)
    context.read<GlobalBloc>().add(
          SignUp(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            userType: _userType.toString(), // ✅ add this in your SignUp event/model
          ),
        );
  }

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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIGNUP'.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const SizedBox(
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

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                    _DecorShapes(),
                  ],
                ),

                const SizedBox(height: 28),

                // ✅ Account type selector
                const Text('Account Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _AccountTypeSelector(
                  value: _userType,
                  onChanged: (v) => setState(() => _userType = v),
                ),

                const SizedBox(height: 16),

                // Name
                const Text('Name',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                    fillColor: fieldBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    suffixIcon: const Icon(Icons.person_outline),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),

                const SizedBox(height: 16),

                // Email
                const Text('Email',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v.trim());
                    return ok ? null : 'Enter a valid email';
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    suffixIcon: const Icon(Icons.mail_outline),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),

                const SizedBox(height: 16),

                // Password
                const Text('Password',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePwd,
                  textInputAction: TextInputAction.next,
                  validator: _passwordValidator,
                  onChanged: (_) {
                    if (confirmPasswordController.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureCpwd,
                  textInputAction: TextInputAction.done,
                  validator: _confirmPasswordValidator,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureCpwd ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureCpwd = !obscureCpwd),
                    ),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),

                const SizedBox(height: 22),

                BlocConsumer<GlobalBloc, GlobalState>(
                  listener: (context, state) {
                    if (state.signUpStatus == SignUpStatus.success) {
                      toastWidget('User Created Successfully! Login Now',
                          Colors.green);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const NewLoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    } else if (state.signUpStatus == SignUpStatus.failure) {
                      toastWidget(state.errorMessageSignUp.toString(), Colors.red);
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state.signUpStatus == SignUpStatus.loading;
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
                          onPressed: isLoading ? null : () => _submit(context),
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                )
                              : const Text('Sign Up',
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

class _AccountTypeSelector extends StatelessWidget {
  static const accent = Color(0xFFE97C42);
  static const fieldBg = Color(0xFFF4F5F7);

  final int value; // 1 or 2
  final ValueChanged<int> onChanged;

  const _AccountTypeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget seg({
      required String label,
      required int val,
    }) {
      final selected = value == val;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(val),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          seg(label: 'Individual User', val: 1),
          const SizedBox(width: 6),
          seg(label: 'Professional User', val: 2),
        ],
      ),
    );
  }
}

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




// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   static const accent = Color(0xFFE97C42);
//   final _formKey = GlobalKey<FormState>();

//   bool obscurePwd = true;
//   bool obscureCpwd = true;

//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   @override
//   void dispose() {
//     nameController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     super.dispose();
//   }

//   String? _passwordValidator(String? v) {
//     final value = (v ?? '').trim();
//     if (value.isEmpty) return 'Password is required';
//     if (value.length < 6) return 'Min 6 characters';
//     return null;
//   }

//   String? _confirmPasswordValidator(String? v) {
//     final value = (v ?? '').trim();
//     if (value.isEmpty) return 'Confirm your password';
//     if (value != passwordController.text.trim())
//       return 'Passwords do not match';
//     return null;
//   }

//   void _submit(BuildContext context) {
//     // Trigger all validators
//     final ok = _formKey.currentState?.validate() ?? false;
//     if (!ok) return;

//     context.read<GlobalBloc>().add(
//           SignUp(
//             name: nameController.text.trim(),
//             email: emailController.text.trim(),
//             password: passwordController.text.trim(),
//           ),
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final border = OutlineInputBorder(
//       borderRadius: BorderRadius.circular(10),
//       borderSide: const BorderSide(color: Colors.transparent),
//     );

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
//           child: Form(
//             key: _formKey,
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // --- Header ---
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('SIGNUP'.toUpperCase(),
//                         style: const TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.w700)),
//                     const SizedBox(height: 4),
//                     const SizedBox(
//                       width: 66,
//                       height: 3,
//                       child: DecoratedBox(
//                         decoration: BoxDecoration(
//                           color: accent,
//                           borderRadius: BorderRadius.all(Radius.circular(2)),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 22),

//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: const [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Create Account,',
//                               style: TextStyle(
//                                   fontSize: 28, fontWeight: FontWeight.w700)),
//                           SizedBox(height: 6),
//                           Text('Please fill the details to continue!',
//                               style: TextStyle(
//                                   fontSize: 15, color: Colors.black54)),
//                         ],
//                       ),
//                     ),
//                     _DecorShapes(),
//                   ],
//                 ),

//                 const SizedBox(height: 28),

//                 // Name
//                 const Text('Name',
//                     style:
//                         TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: nameController,
//                   textInputAction: TextInputAction.next,
//                   validator: (v) => (v == null || v.trim().isEmpty)
//                       ? 'Name is required'
//                       : null,
//                   decoration: InputDecoration(
//                     isDense: true,
//                     filled: true,
//                     fillColor: const Color(0xFFF4F5F7),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 16),
//                     suffixIcon: const Icon(Icons.person_outline),
//                     enabledBorder: border,
//                     focusedBorder: border,
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Email
//                 const Text('Email',
//                     style:
//                         TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   textInputAction: TextInputAction.next,
//                   validator: (v) {
//                     if (v == null || v.trim().isEmpty)
//                       return 'Email is required';
//                     final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
//                         .hasMatch(v.trim());
//                     return ok ? null : 'Enter a valid email';
//                   },
//                   decoration: InputDecoration(
//                     isDense: true,
//                     filled: true,
//                     fillColor: const Color(0xFFF4F5F7),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 16),
//                     suffixIcon: const Icon(Icons.mail_outline),
//                     enabledBorder: border,
//                     focusedBorder: border,
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Password
//                 const Text('Password',
//                     style:
//                         TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: passwordController,
//                   obscureText: obscurePwd,
//                   textInputAction: TextInputAction.next,
//                   validator: _passwordValidator,
//                   onChanged: (_) {
//                     if (confirmPasswordController.text.isNotEmpty) {
//                       _formKey.currentState?.validate();
//                     }
//                   },
//                   decoration: InputDecoration(
//                     isDense: true,
//                     filled: true,
//                     fillColor: const Color(0xFFF4F5F7),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 16),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                           obscurePwd ? Icons.visibility_off : Icons.visibility),
//                       onPressed: () => setState(() => obscurePwd = !obscurePwd),
//                     ),
//                     enabledBorder: border,
//                     focusedBorder: border,
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 const Text('Confirm Password',
//                     style:
//                         TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: confirmPasswordController,
//                   obscureText: obscureCpwd,
//                   textInputAction: TextInputAction.done,
//                   validator: _confirmPasswordValidator,
//                   decoration: InputDecoration(
//                     isDense: true,
//                     filled: true,
//                     fillColor: const Color(0xFFF4F5F7),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 16),
//                     suffixIcon: IconButton(
//                       icon: Icon(obscureCpwd
//                           ? Icons.visibility_off
//                           : Icons.visibility),
//                       onPressed: () =>
//                           setState(() => obscureCpwd = !obscureCpwd),
//                     ),
//                     enabledBorder: border,
//                     focusedBorder: border,
//                   ),
//                 ),

//                 const SizedBox(height: 22),

//                 BlocConsumer<GlobalBloc, GlobalState>(
//                   listener: (context, state) {
//                     if (state.signUpStatus == SignUpStatus.success) {
//                       toastWidget(
//                           'User Created Successfully! Login Now', Colors.green);
//                       Navigator.of(context).pushAndRemoveUntil(
//                         MaterialPageRoute(
//                             builder: (_) => const NewLoginScreen()),
//                         (Route<dynamic> route) => false, 
//                       );
//                     } else if (state.signUpStatus == SignUpStatus.failure) {
//                       toastWidget(
//                           state.errorMessageSignUp.toString(), Colors.red);
//                     }
//                   },
//                   builder: (context, state) {
//                     final isLoading =
//                         state.signUpStatus == SignUpStatus.loading;
//                     return Center(
//                       child: SizedBox(
//                         width: double.infinity,
//                         child: FilledButton(
//                           style: FilledButton.styleFrom(
//                             backgroundColor: accent,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                           ),
//                           onPressed: isLoading ? null : () => _submit(context),
//                           child: isLoading
//                               ? const Center(
//                                   child: CircularProgressIndicator(
//                                       color: Colors.white))
//                               : const Text('Sign Up',
//                                   style: TextStyle(
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.white)),
//                         ),
//                       ),
//                     );
//                   },
//                 ),

//                 const SizedBox(height: 22),

//                 // Bottom link
//                 InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const NewLoginScreen()),
//                     );
//                   },
//                   child: Center(
//                     child: RichText(
//                       text: const TextSpan(
//                         style: TextStyle(color: Colors.black87, fontSize: 15),
//                         children: [
//                           TextSpan(text: 'Already have an account? '),
//                           TextSpan(
//                             text: 'Login Now',
//                             style: TextStyle(
//                                 color: accent, fontWeight: FontWeight.w700),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _DecorShapes extends StatelessWidget {
//   const _DecorShapes();

//   @override
//   Widget build(BuildContext context) {
//     const light = Color(0xFFFFE1D2);
//     const mid = Color(0xFFF6B79C);
//     const dark = Color(0xFFE97C42);

//     Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
//       return Transform.rotate(
//         angle: angle,
//         child: Container(
//           width: w,
//           height: h,
//           decoration:
//               BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
//         ),
//       );
//     }

//     return SizedBox(
//       width: 110,
//       height: 90,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Positioned(right: -6, top: 0, child: block(light)),
//           Positioned(right: 6, top: 22, child: block(mid, w: 78)),
//           Positioned(right: -12, top: 48, child: block(dark, w: 64, h: 22)),
//         ],
//       ),
//     );
//   }
// }
