import 'package:flutter/material.dart';
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
    final bool hasExtraAccess = widget.role == 'mentor' || widget.role == 'admin';
    
    final List<Widget> pages = [
      const MenteeDashboard(),
      if (hasExtraAccess) const MentorDashboard(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: hasExtraAccess 
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: const Color(0xFF006837),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mentee View'),
                BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Mentor Tools'),
              ],
            )
          : null,
    );
  }
}