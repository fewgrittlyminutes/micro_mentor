import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
=======
import 'package:firebase_auth/firebase_auth.dart';
>>>>>>> 9facca9 (Ishini - Profile & Auth Actions)

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(title: const Text("Admin Approval Portal")),
=======
      appBar: AppBar(
        title: const Text("Admin Approval Portal"),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
>>>>>>> 9facca9 (Ishini - Profile & Auth Actions)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('authorized_users')
            .where('hasRequestedMentor', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No pending applications."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              String email = docs[index].id;
              return Card(
                child: ListTile(
                  title: Text(email),
                  subtitle: const Text("Requesting Mentor Access"),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _approveUser(email),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _approveUser(String email) async {
    await FirebaseFirestore.instance
        .collection('authorized_users')
        .doc(email)
        .update({
      'role': 'mentor',
      'hasRequestedMentor': false,
    });
  }
}