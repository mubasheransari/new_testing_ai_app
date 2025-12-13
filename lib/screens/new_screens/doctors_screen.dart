import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/Bloc/global_bloc.dart';
import 'package:motives_tneww/screens/new_screens/appoinment_list.dart';
import 'package:motives_tneww/screens/new_screens/appointment_notification.dart';
import 'package:motives_tneww/screens/new_screens/appointment_screen.dart';



class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  static const accent = Color(0xFFE97C42);
  static const accentDark = Color(0xFFCC642C);
  static const accentSoft = Color(0xFFFFF1E6);
  static const bg = Color(0xFFF7F8FA);
  static const cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GlobalBloc>().state;
    final professionals = state.loginModel?.professionals ?? [];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
         

              const SizedBox(height: 18),

              // const _SearchField(),

              // const SizedBox(height: 26),

              // SECTION TITLE
              Row(
                children: [
                  const Text(
                    'Top Doctors',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:  [
                        Icon(Icons.star_rounded,
                            size: 14, color: accentDark),
                        SizedBox(width: 4),
                        Text(
                          'Best Rated',
                          style: TextStyle(
                            fontSize: 11,
                            color: accentDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                          NotificationBell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AppointmentListPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

         

              const SizedBox(height: 16),

              // DOCTORS LIST Testing@123
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: professionals.length,
                itemBuilder: (context, index) {
                  final p = professionals[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DoctorCard(
                      name: p.name,
                      title: p.email,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}





class _DoctorCard extends StatelessWidget {
  final String name;
  final String title;

  const _DoctorCard({
    required this.name,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
     },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: DoctorHomeScreen.cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [DoctorHomeScreen.accent, DoctorHomeScreen.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.person_outline,
                    color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: DoctorHomeScreen.accentSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.circle,
                                  size: 8, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: DoctorHomeScreen.accentDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: DoctorHomeScreen.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
                onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> AppointmentBookingPage(doctorName: name)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
