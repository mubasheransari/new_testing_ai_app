import 'package:flutter/material.dart';

import 'appointment_notification.dart';

const _hint = Color(0xFF8E8E93);
const _accent = Color(0xFFFF7A3D);
const _header = Color(0xFFFF9156);

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card(
      {required this.child,
      this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

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
                offset: const Offset(0, 6))
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class AppointmentListPage extends StatelessWidget {
  const AppointmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // same header gradient
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _header],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // title row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text('My Appointments',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ValueListenableBuilder<List<Appointment>>(
                  valueListenable: AppointmentStore.I.items,
                  builder: (_, list, __) {
                    if (list.isEmpty) {
                      return const Center(child: Text('No appointments yet'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 6, bottom: 20),
                      itemBuilder: (_, i) {
                        final a = list[i];
                        return _Card(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.event_available,
                                  color: _accent, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.patientName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16)),
                                    const SizedBox(height: 6),
                                    _kv('Doctor', a.doctorName),
                                    _kv('Country', a.country),
                                    _kv('Date', _fmt(a.date)),
                                    if (a.notes.trim().isNotEmpty)
                                      _kv('Notes', a.notes),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Booked',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: list.length,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => AppointmentStore.I.clear(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear all'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            children: [
              TextSpan(
                  text: '$k: ',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: v),
            ],
          ),
        ),
      );

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
