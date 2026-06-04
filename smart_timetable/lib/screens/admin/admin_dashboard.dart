import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import 'manage_classes.dart';
import 'manage_courses.dart';
import 'manage_lecturers.dart';
import 'manage_rooms.dart';
import 'settings_screen.dart';
import 'generate_timetable.dart';
import 'view_timetable.dart';
import 'admin_profile.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.class_, 'label': 'Classes'},
    {'icon': Icons.book_outlined, 'label': 'Courses'},
    {'icon': Icons.people_outlined, 'label': 'Lecturers'},
    {'icon': Icons.meeting_room_outlined, 'label': 'Rooms'},
    {'icon': Icons.auto_awesome, 'label': 'Generate'},
    {'icon': Icons.calendar_month, 'label': 'Timetable'},
    {'icon': Icons.settings_outlined, 'label': 'Settings'},
    {'icon': Icons.person_outlined, 'label': 'Profile'},
  ];

  final List<Widget> _screens = const [
    ManageClasses(),
    ManageCourses(),
    ManageLecturers(),
    ManageRooms(),
    GenerateTimetable(),
    ViewTimetable(),
    SettingsScreen(),
    AdminProfile(),
  ];

  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      width: 220,
      color: const Color(0xFF1F5C8B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_month, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  'Smart\nTimetable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (isDrawer) Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData,
                            color:
                                isSelected ? Colors.white : Colors.white70,
                            size: 20),
                        const SizedBox(width: 12),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          GestureDetector(
            onTap: () async {
              final router = GoRouter.of(context);
              await AuthService().signOut();
              router.go('/login');
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text('Sign Out',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isMobile
          ? Drawer(child: _buildSidebar(isDrawer: true))
          : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      if (isMobile)
                        IconButton(
                          icon: const Icon(Icons.menu,
                              color: Color(0xFF1F5C8B)),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                      if (isMobile) const SizedBox(width: 8),
                      Text(
                        _navItems[_selectedIndex]['label'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F5C8B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}