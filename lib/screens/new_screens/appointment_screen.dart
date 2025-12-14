import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_tneww/Bloc/global_bloc.dart';
import 'package:motives_tneww/Repository/appointments_repository.dart';

import 'appoinment_list.dart';
import 'appointment_notification.dart';

const _hint = Color(0xFF8E8E93);
const _accent = Color(0xFFFF7A3D);
const _header = Color(0xFFFF9156); //Testing@123

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// ====== BOOKING PAGE (upper design same as BMI) ======
// ignore: must_be_immutable
class AppointmentBookingPage extends StatefulWidget {
  String doctorName;
  AppointmentBookingPage({super.key, required this.doctorName});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final _patientCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    AppointmentStore.I.init();
  }

  @override
  void dispose() {
    _patientCtrl.dispose();
    _doctorCtrl.dispose();
    _countryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1)); // > today
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: DateTime(now.year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _accent,
              primary: _accent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select appointment date')),
      );
      return;
    }
    final a = Appointment(
      patientName: context
          .read<GlobalBloc>()
          .state
          .loginModel!
          .user
          .id
          .toString(),
      doctorName: widget.doctorName,
      country: _countryCtrl.text.trim(),
      date: _date!,
      notes: _notesCtrl.text.trim(),
    );
    await AppointmentStore.I.add(a);

    final box = GetStorage();
    String? token = box.read('auth_token');
    AppointmentsRepo().createAppointment(
      notes: _notesCtrl.text.trim(),
      jwtToken: token!,
      patientName: _patientCtrl.text,
      doctorName: widget.doctorName,
      appointmentDate: _date!.toString(),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Appointment saved')));
    _formKey.currentState!.reset();
    setState(() => _date = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NOTE: we render our own header like BMI, so leave normal AppBar out.
      body: Stack(
        children: [
          // ======= UPPER DESIGN (same as BMI header) =======
          Container(
            height: 230,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _header],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top row: Title + Bell (white like BMI header text)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Appointment Booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        NotificationBell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppointmentListPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ======= UPPER CARD (kept same style as BMI _Card) =======
                  _Card(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Row(
                      children: [
                        // small circular calendar flair (mimic BMI dial vibe)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(
                              colors: [
                                Colors.blue,
                                Colors.green,
                                Colors.orange,
                                Colors.red,
                                Colors.blue,
                              ],
                              stops: [0.0, .46, .70, .90, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.08),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Book your next appointment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _date == null
                                    ? 'Pick a date'
                                    : _fmtDate(_date!),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _date == null ? _hint : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _pickDate,
                                  icon: const Icon(Icons.event_available),
                                  label: const Text('Select Date'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ======= MAIN FORM (rest of design same) =======
                  _Card(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Patient Name'),
                          const SizedBox(height: 8),
                          _filledField(
                            _patientCtrl,
                            'John Doe',
                            validator: _req,
                          ),
                          const SizedBox(height: 14),
                          // _label('Doctor Name'),
                          // const SizedBox(height: 8),
                          // _filledField(_doctorCtrl, 'Dr. Smith',
                          //     validator: _req),
                          const SizedBox(height: 14),
                          _label('Country'),
                          const SizedBox(height: 8),
                          _filledField(
                            _countryCtrl,
                            'Australia',
                            validator: _req,
                          ),
                          const SizedBox(height: 14),
                          // _label('Appointment Date'),
                          // const SizedBox(height: 8),
                          // GestureDetector(
                          //   onTap: _pickDate,
                          //   child: _filledField(
                          //     TextEditingController(
                          //         text: _date == null ? '' : _fmtDate(_date!)),
                          //     'Pick a date (> today)',
                          //     enabled: false,
                          //   ),
                          // ),
                          const SizedBox(height: 14),
                          _label('Notes'),
                          const SizedBox(height: 8),
                          _filledField(_notesCtrl, 'Any notes…', maxLines: 4),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                _save(); // your save method
                                //                              final box = GetStorage();
                                // String? token = box.read('auth_token');
                                //                             AppointmentsRepo().createAppointment(jwtToken: token!, patientName: _patientCtrl.text, doctorName: _doctorCtrl.text, appointmentDate: _date!.toString());
                              },
                              // onPressed: _save,
                              child: const Text(
                                'Save Appointment',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _label(String s) => Text(
    s,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
  );

  Widget _filledField(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      enabled: enabled,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        hintText: hint,
        hintStyle: const TextStyle(color: _hint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

