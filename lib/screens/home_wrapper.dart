import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_navigation.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('authorized_users')
          .doc(user?.email?.toLowerCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text("Access Denied", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("You are not on the authorized list for MM 2.0. Please contact the admin.", textAlign: TextAlign.center),
                  ),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text("Back to Login"),
                  ),
                ],
              ),
            ),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'mentee';

        return MainNavigation(role: role);
      },
    );
  }
}