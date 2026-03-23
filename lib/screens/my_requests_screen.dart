import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _markAllAsRead(user?.email); 
  }
  
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    _markAllAsRead(user?.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Sent Requests"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF006837),
        elevation: 0,
      ),
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
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              String status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  leading: Icon(
                    status == 'accepted' ? Icons.check_circle : 
                    status == 'declined' ? Icons.cancel : Icons.hourglass_top,
                    color: _getStatusColor(status),
                  ),
                  
                  title: Text("Topic: ${data['menteeMessage']}", maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("Status: ${status.toUpperCase()}", 
                    style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                  
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _showDeleteConfirmation(context, docId, status),
                  ),
                  
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status == 'completed') ...[
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.stars, color: Colors.blue, size: 40),
                                  const SizedBox(height: 8),
                                  const Text("Session Completed!", 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  const Text("We hope you learned something great!", textAlign: TextAlign.center),
                                  const SizedBox(height: 15),

                                  if (data['isReviewed'] != true)
                                    ElevatedButton.icon(
                                      onPressed: () => _showReviewDialog(context, docId, data['mentorEmail']),
                                      icon: const Icon(Icons.rate_review),
                                      label: const Text("Rate Mentor"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF006837),
                                        foregroundColor: Colors.white,
                                      ),
                                    )
                                  else
                                    const Text("Feedback Submitted ✅", 
                                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                          ] else if (status == 'accepted') ...[
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

  Color _getStatusColor(String status) {
    if (status == 'accepted') return Colors.green;
    if (status == 'declined') return Colors.red;
    if (status == 'completed') return Colors.blue;
    return Colors.orange;
  }

  void _showDeleteConfirmation(BuildContext context, String docId, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'pending' ? "Withdraw Request?" : "Delete Record?"),
        content: Text(status == 'pending' 
            ? "Are you sure you want to cancel this request?" 
            : "This will remove the request from your history."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, String docId, String mentorEmail) {
    final TextEditingController reviewController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Rate your Session"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("How was your experience?"),
              const SizedBox(height: 10),
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: rating.toString(),
                activeColor: const Color(0xFF006837),
                onChanged: (val) => setState(() => rating = val),
              ),
              Text("${rating.toInt()} Stars", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  hintText: "Write a short thank you note...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006837)),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('reviews').add({
                  'mentorEmail': mentorEmail.toLowerCase().trim(),
                  'rating': rating,
                  'reviewText': reviewController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
                  'isReviewed': true,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thank you for your feedback!")),
                  );
                }
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead(String? email) async {
    if (email == null) return;
    
    var unreadDocs = await FirebaseFirestore.instance
        .collection('notifications')
        .where('menteeEmail', isEqualTo: email.toLowerCase())
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}