import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_tneww/Bloc/global_bloc.dart';
import 'package:motives_tneww/Model/login_model.dart';
import 'package:motives_tneww/screens/new_screens/appointment_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/screens/new_screens/doctors_screen.dart';
import 'package:motives_tneww/screens/new_screens/professional_profiles_screen.dart';
import '../scan/scan_screen.dart';
import 'bmi_calculation_screen.dart';
import 'calories_Calulation_screen.dart';
import 'login_screen.dart';

class RootTabs extends StatefulWidget {
  const RootTabs({super.key});
  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  final _pages = const [
    BmiPage(),
    CaloriesPage(),
    NewScanScreen(),
    ProfilePage(),
 DoctorHomeScreen() //ProfessionalProfilesScreen() // AppointmentBookingPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) async {
          if (i == 5) {
            // Logout item
            final ok = await showLogoutDialog(context); // use your dialog
            if (ok == true) {
              // context.read<GlobalBloc>().add(Logout()); // optional
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const NewLoginScreen()),
                (_) => false,
              );
            }
            return; // don't change _index
          }
          setState(() => _index = i);
        },

        // onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF7A3D),
        unselectedItemColor: const Color(0xFFB4B4B4),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'BMI'),
          BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety), label: 'Calories'),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.storefront_outlined), label: 'Store'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Scan Juice'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_online), label: 'Appointment'),
          BottomNavigationBarItem(
              icon: Icon(Icons.logout_rounded), label: 'Logout'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _accent = Color(0xFFFF7A3D);
  static const _header = Color(0xFFFF9156);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ORANGE APP BAR BACKGROUND
          Container(
            height: 210,
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
                  const SizedBox(height: 12),
                  // Title
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NewScanScreen()));
                    },
                    child: Center(
                      child: Text('My Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          )),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PROFILE CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                /*    Stack(
                                  children: [
                                    // const CircleAvatar(
                                    //   radius: 28,
                                    //   backgroundImage: NetworkImage(
                                    //     'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=400',
                                    //   ),
                                    // ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(.08),
                                              blurRadius: 6,
                                            )
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const CircleAvatar(
                                          radius: 10,
                                          backgroundColor: _accent,
                                          child: Icon(Icons.edit,
                                              size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),*/
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          context
                                              .read<GlobalBloc>()
                                              .state
                                              .loginModel!
                                              .user
                                              .name,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700)),
                                      SizedBox(height: 4),
                                      Text(
                                          context
                                              .read<GlobalBloc>()
                                              .state
                                              .loginModel!
                                              .user
                                              .email,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF8E8E93))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: MetricChip(
                                    value: context
                                        .read<GlobalBloc>()
                                        .state
                                        .loginModel!
                                        .user
                                        .weight
                                        .toString(),
                                    unit: 'kg',
                                    label: 'Weight',
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: MetricChip(
                                    value: context
                                        .read<GlobalBloc>()
                                        .state
                                        .loginModel!
                                        .user
                                        .height
                                        .toString(),
                                    unit: 'cm',
                                    label: 'Height',
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: MetricChip(
                                    value: context
                                        .read<GlobalBloc>()
                                        .state
                                        .loginModel!
                                        .user
                                        .age
                                        .toString(),
                                    unit: 'year',
                                    label: 'Age',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // MENU LIST
                  const _MenuSection(
                    items: [
                      MenuItemData(
                          icon: Icons.chat_bubble_outline, title: 'Blog'),
                      MenuItemData(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Subscription Plans'),
                      MenuItemData(
                          icon: Icons.favorite_border,
                          title: 'Preferred Workouts & Nutrition'),
                      MenuItemData(
                          icon: Icons.access_time, title: 'Daily Reminder'),
                      MenuItemData(
                          icon: Icons.assignment_outlined,
                          title: 'Assigned Workout & Diet'),
                      MenuItemData(
                          icon: Icons.settings_outlined, title: 'Settings'),
                      MenuItemData(
                          icon: Icons.info_outline, title: 'About App'),
                      MenuItemData(
                          icon: Icons.logout,
                          title: 'Logout',
                          isDestructive: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricChip extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  const MetricChip({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                    text: ' $unit',
                    style: const TextStyle(color: Color(0xFF8E8E93))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<MenuItemData> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _MenuTile(data: items[i]),
            if (i != items.length - 1)
              const Divider(
                  height: 1,
                  thickness: .6,
                  indent: 56,
                  color: Color(0xFFE9E9EA)),
          ],
        ],
      ),
    );
  }
}

class MenuItemData {
  final IconData icon;
  final String title;
  final bool isDestructive;
  const MenuItemData({
    required this.icon,
    required this.title,
    this.isDestructive = false,
  });
}

class _MenuTile extends StatelessWidget {
  final MenuItemData data;
  const _MenuTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final color =
        data.isDestructive ? const Color(0xFFEB5757) : const Color(0xFF111111);
    return ListTile(
      leading: Icon(data.icon, color: const Color(0xFF373737)),
      title: Text(data.title,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: color)),
      // trailing:
      //     const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
      onTap: () {
        if (data.title == 'Logout') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out')),
          );
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DetailPage(title: data.title),
        ));
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String title;
  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child:
            Text('$title Page', style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Text('$title Screen',
            style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

Future<bool?> showLogoutDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'Logout',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, __, ___) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: curved,
            child: Opacity(
              opacity: anim.value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.06),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon badge
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF7A7A),
                                  const Color(0xFFE53935),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33E53935),
                                  blurRadius: 8,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: Colors.white, size: 34),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Log out?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can always sign back in. Are you sure you want to end your session now?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    side: BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    var box = GetStorage();
                                    box.remove('email');
                                    box.remove('password');
                                    box.remove('auth_token');

                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const NewLoginScreen()),
                                      (Route<dynamic> route) =>
                                          false, // remove everything Testing@123
                                    );
                                  },
                                  child: const Text(
                                    'Log out',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
