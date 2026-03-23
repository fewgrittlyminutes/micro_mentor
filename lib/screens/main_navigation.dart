import 'package:flutter/material.dart';
import 'mentee_dashboard.dart';
import 'mentor_dashboard.dart';
import 'admin_approval_screen.dart';

class MainNavigation extends StatefulWidget {
  final String role;
  const MainNavigation({super.key, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget mainBody;
    Widget? bottomBar;

    if (widget.role == 'admin') {
      mainBody = const AdminApprovalScreen();
      bottomBar = null;
    } else if (widget.role == 'mentor') {
      final List<Widget> mentorPages = [
        MenteeDashboard(role: widget.role), 
        const MentorDashboard(),
      ];
      mainBody = mentorPages[_selectedIndex];
      bottomBar = BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF006837),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mentee View'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Mentor Tools'),
        ],
      );
    } else {
      mainBody = MenteeDashboard(role: widget.role); 
      bottomBar = null;
    }

    return Scaffold(
      body: mainBody,
      bottomNavigationBar: bottomBar,
    );
  }
}