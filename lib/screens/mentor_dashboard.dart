import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';
>>>>>>> 9facca9 (Ishini - Profile & Auth Actions)

class MentorDashboard extends StatelessWidget {
  const MentorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentor Tools"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF006837),
        elevation: 0,
<<<<<<< HEAD
=======
        actions: [
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
>>>>>>> 9facca9 (Ishini - Profile & Auth Actions)
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
}