import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewOtpVerificationScreen extends StatefulWidget {
  const NewOtpVerificationScreen({super.key});

  @override
  State<NewOtpVerificationScreen> createState() =>
      _NewOtpVerificationScreenState();
}

class _NewOtpVerificationScreenState extends State<NewOtpVerificationScreen> {
  static const accent = Color(0xFFE97C42);
  final int length = 4;

  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(length, (_) => TextEditingController());
    _nodes = List.generate(length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get code => _ctrls.map((c) => c.text).join();

  void _onChanged(int i, String v) {
    if (v.length == 1 && i < length - 1) {
      _nodes[i + 1].requestFocus();
    }
    if (v.isEmpty && i > 0) {
      // backspace jumps left
      _nodes[i - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _onPaste(String text) async {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    for (var i = 0; i < length; i++) {
      _ctrls[i].text = i < digits.length ? digits[i] : '';
    }
    if (digits.length >= length) _nodes.last.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final boxBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E6EA)),
    );

    final enabled = code.length == length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: accent),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OTP Verification',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'OTP has been sent on mobile number\nPlease enter OTP to verify the number',
                style:
                    TextStyle(fontSize: 15, color: Colors.black45, height: 1.4),
              ),
              const SizedBox(height: 24),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i == length - 1 ? 0 : 12),
                    child: SizedBox(
                      width: 48,
                      child: TextField(
                        controller: _ctrls[i],
                        focusNode: _nodes[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        onChanged: (v) => _onChanged(i, v),
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          enabledBorder: boxBorder,
                          focusedBorder: boxBorder.copyWith(
                            borderSide:
                                const BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: const Color(0xFFE7A684),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: enabled
                      ? () {
                          // TODO: call verify API with `code`
                          // print('OTP: $code');
                        }
                      : null,
                  child: const Text(
                    'Verify & Proceed',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // Paste helper (optional)
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) _onPaste(data!.text!);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black38,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Paste code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
