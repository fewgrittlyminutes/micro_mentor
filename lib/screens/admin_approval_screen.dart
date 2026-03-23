import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildAdminStats()),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Pending Approval Requests", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('authorized_users')
                .where('hasRequestedMentor', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              var docs = snapshot.data?.docs ?? [];
              
              if (docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text("No pending applications at the moment.", 
                      style: TextStyle(color: Colors.grey))
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var userData = docs[index].data() as Map<String, dynamic>;
                    String email = docs[index].id;
                    return _buildApplicantCard(email, userData);
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('authorized_users').snapshots(),
      builder: (context, snapshot) {
        var docs = snapshot.data?.docs ?? [];
        
        var nonAdminDocs = docs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          return data['role'] != 'admin'; 
        }).toList();

        int totalServiceUsers = nonAdminDocs.length;
        int mentors = nonAdminDocs.where((d) => d['role'] == 'mentor').length;
        int pending = nonAdminDocs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          return data['hasRequestedMentor'] == true;
        }).length;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _statCard("Total Users", totalServiceUsers.toString(), Colors.blue),
              const SizedBox(width: 10),
              _statCard("Mentors", mentors.toString(), Colors.green),
              const SizedBox(width: 10),
              _statCard("Pending", pending.toString(), Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border(left: BorderSide(color: color, width: 4))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard(String email, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF006837).withOpacity(0.1),
          child: Text(
            data['name']?[0] ?? "?", 
            style: const TextStyle(color: Color(0xFF006837), fontWeight: FontWeight.bold)
          ),
        ),
        title: Text(data['name'] ?? "New Applicant", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(email, style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoSection("Professional Bio", data['pendingBio']),
                _infoSection("Experience Details", data['pendingExperience']),
                _infoSection("Claimed Skills", data['pendingSkills']?.join(', ')),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _approveMentor(email, data),
                        child: const Text("Approve Mentor"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red, 
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _rejectMentor(email),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoSection(String label, String? content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(content ?? "Not provided", style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  void _approveMentor(String email, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('authorized_users')
        .doc(email.toLowerCase())
        .update({
      'role': 'mentor',
      'hasRequestedMentor': false,
      'bio': data['pendingBio'] ?? "NSBM Mentor",
      'skills': data['pendingSkills'] ?? [],
      'experience': data['pendingExperience'] ?? "",
      'pendingBio': FieldValue.delete(),
      'pendingSkills': FieldValue.delete(),
      'pendingExperience': FieldValue.delete(),
    });
  }

  void _rejectMentor(String email) async {
    await FirebaseFirestore.instance
        .collection('authorized_users')
        .doc(email.toLowerCase())
        .update({
      'hasRequestedMentor': false,
      'rejectionReason': "Application declined. Your profile doesn't meet our current requirements.",
      'pendingBio': FieldValue.delete(),
      'pendingSkills': FieldValue.delete(),
      'pendingExperience': FieldValue.delete(),
    });
  }
}