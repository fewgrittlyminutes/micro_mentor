import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleMicrosoftSignIn(BuildContext context) async {
    try {
      final microsoftProvider = OAuthProvider('microsoft.com');
      
      microsoftProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(microsoftProvider);
      final User? user = userCredential.user;

      if (user != null) {
        String email = user.email!.toLowerCase().trim();

        if (email.endsWith('@students.nsbm.ac.lk')) {
          final userRef = FirebaseFirestore.instance.collection('authorized_users').doc(email);
          final userDoc = await userRef.get();

          if (!userDoc.exists) {
            await userRef.set({
              'name': user.displayName ?? email.split('@')[0],
              'role': 'mentee',
              'hasRequestedMentor': false,
              'bio': 'NSBM Student',
              'skills': [],
              'price': 1000.0,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } else {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Access Denied: Please use your NSBM Student Email.")),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance, size: 100, color: Color(0xFF006837)),
              const SizedBox(height: 20),
              const Text(
                "MicroMentor 2.0",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006837),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "University Mentorship Portal",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _handleMicrosoftSignIn(context),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text(
                    "Sign in with Microsoft",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}