import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';

class MentorDashboard extends StatelessWidget {
  const MentorDashboard({super.key});
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentor Tools"),
        actions: [
          _buildNotificationIcon(user?.email),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(role: 'mentor'),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 80, color: Color(0xFF006837)),
            SizedBox(height: 16),
            Text(
              "Mentor Workspace",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Your teaching schedule and sessions\nwill appear here soon.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationIcon(String? email) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('mentorEmail', isEqualTo: email?.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        bool hasAlert = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ),
            ),
            if (hasAlert)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }
}