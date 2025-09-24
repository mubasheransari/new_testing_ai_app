import 'package:flutter/material.dart';
import 'package:motives_tneww/widget/toast_widget.dart';

import '../../Repository/repository.dart';
import 'otp_verification.dart';

class NewForgotPasswordScreen extends StatefulWidget {
  const NewForgotPasswordScreen({super.key});

  @override
  State<NewForgotPasswordScreen> createState() =>
      _NewForgotPasswordScreenState();
}

class _NewForgotPasswordScreenState extends State<NewForgotPasswordScreen> {
  static const accent = Color(0xFFE97C42);
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Forgot password',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                  'Please enter your email address to request\na password reset',
                  style: TextStyle(
                      fontSize: 15, color: Colors.black45, height: 1.4),
                ),
                const SizedBox(height: 24),
                const Text('Email',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email is required';
                    final ok =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                    return ok ? null : 'Enter a valid email';
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter Email',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    suffixIcon:
                        const Icon(Icons.mail_outline, color: Colors.black38),
                    enabledBorder: border,
                    focusedBorder: border,
                    errorBorder: border.copyWith(
                        borderSide: const BorderSide(color: Colors.redAccent)),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final repo = Repository(); // direct use, no Bloc
                      try {
                        final res = await repo
                            .requestPasswordResetHttp(_email.text.trim());
                        if (res.status) {
                          toastWidget("Email has been send to ${_email.text}",
                              Colors.red);
                          // print("response of forget password ${res.message}");
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(content: Text(res.message)),
                          // );
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //       builder: (_) =>
                          //           const NewOtpVerificationScreen()),
                          // );
                        } else {
                          toastWidget("Internal Server Error", Colors.red);
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //       content: Text(res.message.isEmpty
                          //           ? 'Request failed'
                          //           : res.message)),
                          // );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    child: const Text('Continue',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
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
