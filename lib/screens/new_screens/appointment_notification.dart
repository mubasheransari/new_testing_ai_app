import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ====== COLORS (copied from BMI upper design) ======
const _hint = Color(0xFF8E8E93);
const _accent = Color(0xFFFF7A3D);
const _header = Color(0xFFFF9156);

/// ====== MODEL ======
class Appointment {
  final String patientName;
  final String doctorName;
  final String country;
  final DateTime date;
  final String notes;

  Appointment({
    required this.patientName,
    required this.doctorName,
    required this.country,
    required this.date,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'patientName': patientName,
        'doctorName': doctorName,
        'country': country,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
        patientName: j['patientName'] ?? '',
        doctorName: j['doctorName'] ?? '',
        country: j['country'] ?? '',
        date: DateTime.parse(j['date']),
        notes: j['notes'] ?? '',
      );
}

/// ====== STORE (SharedPreferences) ======
class AppointmentStore {
  AppointmentStore._();
  static final I = AppointmentStore._();
  static const _key = 'appt_v1';

  final ValueNotifier<List<Appointment>> items = ValueNotifier([]);

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? [];
    items.value = raw
        .map((e) => Appointment.fromJson(jsonDecode(e)))
        .toList(growable: true);
  }

  Future<void> add(Appointment a) async {
    final p = await SharedPreferences.getInstance();
    final list = [...items.value, a];
    items.value = list;
    await p.setStringList(_key, list.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    items.value = [];
    await p.remove(_key);
  }
}

/// ====== UPPER DESIGN CARD (SAME AS BMI) ======
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// ====== NOTIFICATION BELL WITH BADGE ======
class NotificationBell extends StatefulWidget {
  final VoidCallback onTap;
  const NotificationBell({super.key, required this.onTap});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  @override
  void initState() {
    super.initState();
    AppointmentStore.I.items.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppointmentStore.I.items.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppointmentStore.I.items.value.length;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.notifications_none, size: 28, color: Colors.white),
          ),
          if (c > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Text('$c', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}