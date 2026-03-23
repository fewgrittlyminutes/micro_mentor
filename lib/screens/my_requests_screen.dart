import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My Sent Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('menteeEmail', isEqualTo: user?.email?.toLowerCase())
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No requests sent yet."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text("Topic: ${data['menteeMessage']}", maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("Status: ${status.toUpperCase()}", 
                    style: TextStyle(color: status == 'accepted' ? Colors.green : Colors.orange)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status == 'accepted') ...[
                            const Text("Mentor's Instructions:", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(data['sessionDetails'] ?? "Check back soon for details!"),
                          ] else if (status == 'declined')
                            const Text("This request was declined.", style: TextStyle(color: Colors.red))
                          else
                            const Text("Waiting for mentor to provide time/link..."),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}