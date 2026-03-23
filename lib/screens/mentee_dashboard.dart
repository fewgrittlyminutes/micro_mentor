import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenteeDashboard extends StatelessWidget {
  const MenteeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Portal"),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Find a Mentor", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Expanded(child: Center(child: Text("Mentor List Coming Soon..."))),
            
            ElevatedButton(
              onPressed: () => _submitMentorRequest(context, user?.email),
              child: const Text("Apply to become a Mentor"),
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
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}