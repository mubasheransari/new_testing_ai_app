import 'package:flutter/material.dart';
import 'package:motives_tneww/Bloc/global_bloc.dart';
import 'package:motives_tneww/Model/login_model.dart';
import 'package:motives_tneww/screens/new_screens/appointment_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../scan/scan_screen.dart';
import 'bmi_calculation_screen.dart';
import 'calories_Calulation_screen.dart';

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
    // PlaceholderPage(title: 'Home'),
    //PlaceholderPage(title: 'Diet Plan'),
    // PlaceholderPage(title: 'Store'),
    // PlaceholderPage(title: 'Report'),
    ProfilePage(),
    AppointmentBookingPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
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
