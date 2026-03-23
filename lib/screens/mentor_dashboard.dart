import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorDashboard extends StatelessWidget {
  const MentorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('authorized_users').doc(user?.email?.toLowerCase()).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        bool isAdmin = userData['role'] == 'admin';

        return Scaffold(
          appBar: AppBar(title: const Text("Mentor Tools")),
          body: Column(
            children: [
              if (isAdmin) ...[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Pending Applications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: _buildApprovalList()),
              ] else ...[
                const Expanded(child: Center(child: Text("Your Mentor Schedule will appear here."))),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovalList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('authorized_users')
          .where('hasRequestedMentor', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No pending requests."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            String email = docs[index].id;
            return ListTile(
              title: Text(email),
              trailing: ElevatedButton(
                onPressed: () => _approveUser(email),
                child: const Text("Approve"),
              ),
            );
          },
        );
      },
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