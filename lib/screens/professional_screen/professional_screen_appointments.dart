import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:motives_tneww/Bloc/global_bloc.dart';
import 'package:motives_tneww/Bloc/global_event.dart';
import 'package:motives_tneww/Model/login_model.dart';

import 'appointment_done_storage.dart';



enum ApptGroup { all, today, future, done, missed }

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  ApptGroup _group = ApptGroup.all;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GlobalBloc>().state;

    final all = (state.loginModel?.appointments ?? []).toList();

    // ✅ sort by date (nulls last)
    all.sort((a, b) {
      final da = _parseApptDate(a.appointmentDate);
      final db = _parseApptDate(b.appointmentDate);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    final today = _todayDateOnly(DateTime.now());
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    int totalCount = all.length;
    int doneCount = all.where((x) => AppointmentDoneStorage.isDone(x.id)).length;

    int todayCount = all.where((x) {
      final d = _parseApptDate(x.appointmentDate);
      if (d == null) return false;
      return isSameDay(_todayDateOnly(d), today);
    }).length;

    int futureCount = all.where((x) {
      final d = _parseApptDate(x.appointmentDate);
      if (d == null) return false;
      return _todayDateOnly(d).isAfter(today);
    }).length;

    int missedCount = all.where((x) {
      final d = _parseApptDate(x.appointmentDate);
      if (d == null) return false;
      final isPast = _todayDateOnly(d).isBefore(today);
      final isDone = AppointmentDoneStorage.isDone(x.id);
      return isPast && !isDone;
    }).length;

    final filtered = _applyFilter(all, today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              var box = GetStorage();
var email = box.read('email');
var password = box.read('password');
context.read<GlobalBloc>().add(Login(email:email,password: password ));

            }),//Testing@123
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _SummaryRow(
              total: totalCount,
              today: todayCount,
              future: futureCount,
              done: doneCount,
              missed: missedCount,
            ),
          ),

          // ✅ Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _FilterChips(
              group: _group,
              onChanged: (g) => setState(() => _group = g),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // ✅ List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No appointments found'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final appt = filtered[index];
                      final status = _statusFor(appt);
                      final dateText = _formatDate(appt.appointmentDate);

                      final isDone = AppointmentDoneStorage.isDone(appt.id);

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      appt.patientName ?? 'Unknown patient',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _StatusPill(status: status),
                                ],
                              ),
                              const SizedBox(height: 8),

                              _InfoLine(
                                icon: Icons.calendar_month,
                                text: dateText,
                              ),
                              const SizedBox(height: 6),
                              _InfoLine(
                                icon: Icons.note,
                                text: 'Notes: ${appt.notes ?? "-"}',
                              ),
                              const SizedBox(height: 6),
                              _InfoLine(
                                icon: Icons.public,
                                text: 'Country: ${appt.country ?? "-"}',
                              ),

                              // if ((appt.notes ?? '').trim().isNotEmpty) ...[
                              //   const SizedBox(height: 8),
                              //   Text(
                              //     appt.notes!.trim(),
                              //     style: const TextStyle(fontSize: 13.5),
                              //   ),
                              // ],

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isDone
                                          ? null
                                          : () async {
                                              await AppointmentDoneStorage.setDone(appt.id, true);
                                              if (!mounted) return;
                                              setState(() {});
                                            },
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Mark Done'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: !isDone
                                          ? null
                                          : () async {
                                              await AppointmentDoneStorage.setDone(appt.id, false);
                                              if (!mounted) return;
                                              setState(() {});
                                            },
                                      icon: const Icon(Icons.undo),
                                      label: const Text('Undo'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------- helpers ----------------

  List<Appointment> _applyFilter(List<Appointment> all, DateTime today) {
    final list = all;

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    switch (_group) {
      case ApptGroup.all:
        return list;

      case ApptGroup.today:
        return list.where((x) {
          final d = _parseApptDate(x.appointmentDate);
          if (d == null) return false;
          return sameDay(_todayDateOnly(d), today);
        }).toList();

      case ApptGroup.future:
        return list.where((x) {
          final d = _parseApptDate(x.appointmentDate);
          if (d == null) return false;
          return _todayDateOnly(d).isAfter(today);
        }).toList();

      case ApptGroup.done:
        return list.where((x) => AppointmentDoneStorage.isDone(x.id)).toList();

      case ApptGroup.missed:
        return list.where((x) {
          final d = _parseApptDate(x.appointmentDate);
          if (d == null) return false;
          final past = _todayDateOnly(d).isBefore(today);
          final done = AppointmentDoneStorage.isDone(x.id);
          return past && !done;
        }).toList();
    }
  }

  AppointmentStatus _statusFor(Appointment appt) {
    final isDone = AppointmentDoneStorage.isDone(appt.id);
    if (isDone) return AppointmentStatus.done;

    final d = _parseApptDate(appt.appointmentDate);
    if (d == null) return AppointmentStatus.unknown;

    final today = _todayDateOnly(DateTime.now());
    final apptDay = _todayDateOnly(d);

    if (apptDay.isBefore(today)) return AppointmentStatus.missed;
    if (apptDay.isAfter(today)) return AppointmentStatus.future;
    return AppointmentStatus.today;
  }

  DateTime _todayDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _parseApptDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final v = s.trim();

    // ✅ Try ISO (2025-12-14T10:00:00Z)
    final iso = DateTime.tryParse(v);
    if (iso != null) return iso.toLocal();

    // ✅ Try common formats
    for (final f in [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy/MM/dd',
    ]) {
      try {
        return DateFormat(f).parse(v, true).toLocal();
      } catch (_) {}
    }
    return null;
  }

  String _formatDate(String? s) {
    final d = _parseApptDate(s);
    if (d == null) return s ?? '-';
    return DateFormat('EEE, dd MMM yyyy').format(d);
  }
}

// ---------------- UI Widgets ----------------//Testing@123

enum AppointmentStatus { today, future, missed, done, unknown }

class _StatusPill extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      AppointmentStatus.today => 'Today',
      AppointmentStatus.future => 'Upcoming',
      AppointmentStatus.missed => 'Missed',
      AppointmentStatus.done => 'Done',
      AppointmentStatus.unknown => 'Unknown',
    };

    final bg = switch (status) {
      AppointmentStatus.today => Colors.orange.withOpacity(0.15),
      AppointmentStatus.future => Colors.blue.withOpacity(0.15),
      AppointmentStatus.missed => Colors.red.withOpacity(0.15),
      AppointmentStatus.done => Colors.green.withOpacity(0.15),
      AppointmentStatus.unknown => Colors.grey.withOpacity(0.15),
    };

    final fg = switch (status) {
      AppointmentStatus.today => Colors.orange.shade800,
      AppointmentStatus.future => Colors.blue.shade800,
      AppointmentStatus.missed => Colors.red.shade800,
      AppointmentStatus.done => Colors.green.shade800,
      AppointmentStatus.unknown => Colors.grey.shade800,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total, today, future, done, missed;
  const _SummaryRow({
    required this.total,
    required this.today,
    required this.future,
    required this.done,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.withOpacity(0.10),
          ),
          child: Column(
            children: [
              Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Total', total),
        const SizedBox(width: 8),
        chip('Today', today),
        const SizedBox(width: 8),
        chip('Future', future),
        const SizedBox(width: 8),
        chip('Done', done),
        const SizedBox(width: 8),
        chip('Missed', missed),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final ApptGroup group;
  final ValueChanged<ApptGroup> onChanged;

  const _FilterChips({required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: group == ApptGroup.all,
          onSelected: (_) => onChanged(ApptGroup.all),
        ),
        ChoiceChip(
          label: const Text('Today'),
          selected: group == ApptGroup.today,
          onSelected: (_) => onChanged(ApptGroup.today),
        ),
        ChoiceChip(
          label: const Text('Future'),
          selected: group == ApptGroup.future,
          onSelected: (_) => onChanged(ApptGroup.future),
        ),
        ChoiceChip(
          label: const Text('Done'),
          selected: group == ApptGroup.done,
          onSelected: (_) => onChanged(ApptGroup.done),
        ),
        ChoiceChip(
          label: const Text('Missed'),
          selected: group == ApptGroup.missed,
          onSelected: (_) => onChanged(ApptGroup.missed),
        ),
      ],
    );
  }
}
