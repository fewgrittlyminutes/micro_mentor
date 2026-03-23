import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Session Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('mentorEmail', isEqualTo: user?.email?.toLowerCase().trim())
            .snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          var docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return const Center(child: Text("No requests yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              String status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    backgroundColor: status == 'accepted' ? Colors.green[100] : Colors.orange[100],
                    child: Icon(
                      status == 'accepted' ? Icons.check : Icons.hourglass_empty,
                      color: status == 'accepted' ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(data['menteeName'] ?? "Unknown Student", 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "Topic: ${data['menteeMessage'] ?? 'No specific details provided.'}",
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text("From: ${data['menteeEmail']}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: status == 'pending' 
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _showAcceptDialog(context, docId), 
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _updateStatus(docId, 'declined'),
                          ),
                        ],
                      )
                    : status == 'accepted'
                        ? ElevatedButton.icon(
                            onPressed: () => _updateStatus(docId, 'completed'),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text("Done"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006837),
                              foregroundColor: Colors.white,
                            ),
                          )
                        : Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAcceptDialog(BuildContext context, String docId) {
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Accept Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter session details (Time, App, Link):"),
            const SizedBox(height: 10),
            TextField(
              controller: detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "e.g., Monday 10AM on Zoom. Link: ...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006837)),
            onPressed: () {
              if (detailsController.text.isNotEmpty) {
                _updateStatus(docId, 'accepted', details: detailsController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Send & Accept", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String id, String status, {String? details}) async {
    final docRef = FirebaseFirestore.instance.collection('notifications').doc(id);
    
    if (status == 'declined') {
      try {
        DocumentSnapshot doc = await docRef.get();
        var data = doc.data() as Map<String, dynamic>;
        
        String mentorEmail = data['mentorEmail'];
        double amount = (data['amount'] ?? 1000).toDouble();
        String? sessionId = data['sessionId'];

        WriteBatch batch = FirebaseFirestore.instance.batch();

        batch.update(docRef, {
          'status': 'declined',
          'isRead': false,
        });

        if (sessionId != null && sessionId.isNotEmpty) {
          batch.update(FirebaseFirestore.instance.collection('sessions').doc(sessionId), {
            'status': 'refunded',
            'isRead': false,
          });
        }

        batch.update(
          FirebaseFirestore.instance.collection('authorized_users').doc(mentorEmail.toLowerCase().trim()), 
          {
            'revenue': FieldValue.increment(-amount),
          }
        );

        await batch.commit();
      } catch (e) {
        print("Refund error: $e");
      }
    } else {
      docRef.update({
        'status': status,
        'sessionDetails': details ?? "",
        'isRead': false,
      });
    }
  }
}