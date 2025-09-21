import 'package:flutter/material.dart';

import '../scan/scan_screen.dart';
import 'custom_bottom.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _brand = Color(0xFFFF7E44); // top orange
  static const _brandDark = Color(0xFFFF6A2C);
  static const _chipBg = Color(0xFFFDF2ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 4, // "Profile" tab selected
        onTap: (i) {
          // TODO: navigate to other tabs dynamically
          // e.g., if (i == 0) Navigator.push(...);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient and card
            _Header(),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => ScanPage()));
                    },
                    child: _SectionTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Blog',
                    ),
                  ),
                  _DividerThin(),
                  _SectionTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Subscription Plans',
                  ),
                  _DividerThin(),
                  _SectionTile(
                    icon: Icons.favorite_border,
                    title: 'Preferred Workouts & Nutrition',
                  ),
                  _DividerThin(),
                  _SectionTile(
                    icon: Icons.access_time_rounded,
                    title: 'Daily Reminder',
                  ),
                  _DividerThin(),
                  _SectionTile(
                    icon: Icons.assignment_outlined,
                    title: 'Assigned Workout & Diet',
                  ),
                  _DividerThin(),
                  _SectionTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                  ),
                  _DividerThin(),
                  _SectionTile(
                    icon: Icons.info_outline,
                    title: 'About App',
                  ),
                  _DividerThin(),
                  _SectionTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    trailingColor: Colors.black54,
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          // Gradient top bar
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8752), Color(0xFFFF6C2F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            alignment: Alignment.center,
            child: InkWell(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ScanPage()));
              },
              child: Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          // Floating profile card
          Positioned.fill(
            top: 70,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: MediaQuery.of(context).size.width - 24,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 0,
                      color: Color(0x1A000000),
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(
                                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300',
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.verified,
                                    size: 14, color: Color(0xFFFF6C2F)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hassam Ullah',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'hassamullah066@gmail.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            print("print");
                          },
                          child: Expanded(
                              child: _StatChip(
                                  value: '55', unit: 'kg', label: 'Weight')),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                            child: _StatChip(
                                value: '170', unit: 'cm', label: 'Height')),
                        SizedBox(width: 10),
                        Expanded(
                            child: _StatChip(
                                value: '21', unit: 'year', label: 'Age')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  const _StatChip(
      {required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE1D4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? trailingColor;
  const _SectionTile({
    required this.icon,
    required this.title,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing:
          Icon(Icons.chevron_right, color: trailingColor ?? Colors.black26),
      onTap: () {
        // TODO: navigate
      },
    );
  }
}

class _DividerThin extends StatelessWidget {
  const _DividerThin();
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.6);
  }
}
