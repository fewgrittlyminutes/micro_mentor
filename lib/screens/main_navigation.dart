import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mentee_dashboard.dart';
import 'mentor_dashboard.dart';

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
    List<Widget> pages = [const MenteeDashboard()];
    if (widget.role == 'mentor' || widget.role == 'admin') {
      pages.add(const MentorDashboard());
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: (widget.role == 'mentor' || widget.role == 'admin')
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: const Color(0xFF006837),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Mentee View'),
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize), label: 'Mentor Tools'),
              ],
            )
          : null,
    );
  }
}