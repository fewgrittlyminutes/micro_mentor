import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
<<<<<<< HEAD
=======
import 'edit_profile_screen.dart';
>>>>>>> 9facca9 (Ishini - Profile & Auth Actions)

class MenteeDashboard extends StatelessWidget {
  final String role; 

  const MenteeDashboard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    final bool canApply = role == 'mentee';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Portal"),
        actions: [
          IconButton(
<<<<<<< HEAD
=======
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(role: role)),
              );
            },
          ),
          IconButton(
>>>>>>> 9facca9 (Ishini - Profile & Auth Actions)
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Find a Mentor", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const Expanded(
              child: Center(child: Text("Mentor List Coming Soon...")),
            ),
            
            if (canApply)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF006837),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _submitMentorRequest(context, user?.email),
                  child: const Text("Apply to become a Mentor"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submitMentorRequest(BuildContext context, String? email) async {
    try {
      if (email == null) return;

      await FirebaseFirestore.instance
          .collection('authorized_users')
          .doc(email.toLowerCase())
          .update({
        'hasRequestedMentor': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Application submitted!")),
      );
    } catch (e) {
      print("Firestore Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"), 
          backgroundColor: Colors.red
        ),
      );
    }
  }
}