import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mentor Tools"),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen(role: 'mentor')),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF006837),
            labelColor: Color(0xFF006837),
            tabs: [
              Tab(text: "Insights", icon: Icon(Icons.bar_chart)),
              Tab(text: "New Requests", icon: Icon(Icons.mail_outline)),
              Tab(text: "Pending Sessions", icon: Icon(Icons.bolt)),
              Tab(text: "Completed Sessions", icon: Icon(Icons.check_circle_outline)),
              Tab(text: "Reviews", icon: Icon(Icons.star_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInsightsTab(user?.email),
            _buildSessionList(user?.email, 'pending'),
            _buildSessionList(user?.email, 'accepted'),
            _buildSessionList(user?.email, 'completed'),
            _buildReviewTab(user?.email),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(String? mentorEmail, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('mentorEmail', isEqualTo: mentorEmail?.toLowerCase().trim())
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Query Error: ${snapshot.error}", 
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text("No $status sessions found.", style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;

            return Card(
              child: ListTile(
                title: Text(data['menteeName'] ?? "Student"),
                subtitle: Text(data['menteeMessage'] ?? ""),
                trailing: _buildActionButton(status, docId, data),
              ),
            );
          },
        );
      },
    );
  }

  Widget? _buildActionButton(String status, String docId, Map<String, dynamic> data) {
    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            onPressed: () => _showAcceptDialog(docId),
            tooltip: "Accept Request",
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
            onPressed: () => _showDeclineConfirmation(docId),
            tooltip: "Decline Request",
          ),
        ],
      );
    } else if (status == 'accepted') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006837),
          foregroundColor: Colors.white,
        ),
        onPressed: () => _markAsComplete(docId),
        child: const Text("Finish"),
      );
    }
    return const Icon(Icons.verified, color: Colors.blue);
  }

  void _showAcceptDialog(String docId) {
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Accept & Send Link"),
        content: TextField(
          controller: detailsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Enter Zoom link, time, or instructions...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006837)),
            onPressed: () async {
              if (detailsController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
                  'status': 'accepted',
                  'sessionDetails': detailsController.text,
                  'isRead': false,
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Confirm & Send", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeclineConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Decline Request?"),
        content: const Text("Are you sure you want to decline this mentorship request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Go Back"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(docId)
                  .update({
                'status': 'declined',
                'isRead': false,
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Yes, Decline", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _markAsComplete(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'status': 'completed', 'isRead': false});
  }

  Widget _buildReviewTab(String? mentorEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('mentorEmail', isEqualTo: mentorEmail?.toLowerCase().trim())
          .where('timestamp', isNotEqualTo: null)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var reviews = snapshot.data?.docs ?? [];
        if (reviews.isEmpty) {
          return const Center(
            child: Text("No reviews yet. Keep mentoring to earn feedback!", 
              style: TextStyle(color: Colors.grey))
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            var data = reviews[index].data() as Map<String, dynamic>;
            int rating = (data['rating'] ?? 0).toInt();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber[100],
                  child: Text(rating.toString(), 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
                title: Row(
                  children: List.generate(5, (i) => Icon(
                    Icons.star,
                    size: 16,
                    color: i < rating ? Colors.amber : Colors.grey[300],
                  )),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data['reviewText'] ?? "No comment provided.",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInsightsTab(String? email) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('mentorEmail', isEqualTo: email?.toLowerCase().trim())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        int completed = docs.where((d) => d['status'] == 'completed').length;
        int active = docs.where((d) => d['status'] == 'accepted').length;
        int total = docs.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Performance Overview", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  _buildSimpleStatCard("Total Requests", total.toString(), Colors.blue),
                  const SizedBox(width: 10),
                  _buildSimpleStatCard("Completion Rate", 
                      "${total == 0 ? 0 : ((completed / total) * 100).toInt()}%", Colors.green),
                ],
              ),
              const SizedBox(height: 20),

              const Text("Session Distribution", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildLinearChart(completed, active, total),
              
              const SizedBox(height: 30),
              
              _buildRatingSummary(email),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinearChart(int completed, int active, int total) {
    if (total == 0) return const Text("No data to display.");
    double completedWidth = (completed / total);
    double activeWidth = (active / total);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 20,
            width: double.infinity,
            child: Row(
              children: [
                Expanded(flex: (completedWidth * 100).toInt(), child: Container(color: Colors.green)),
                Expanded(flex: (activeWidth * 100).toInt(), child: Container(color: Colors.blue)),
                Expanded(flex: ((1 - (completedWidth + activeWidth)) * 100).toInt(), 
                    child: Container(color: Colors.grey[300])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _chartLegend("Completed", Colors.green),
            _chartLegend("Active", Colors.blue),
            _chartLegend("Pending", Colors.grey),
          ],
        )
      ],
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildRatingSummary(String? email) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('mentorEmail', isEqualTo: email?.toLowerCase().trim())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        var reviews = snapshot.data!.docs;
        double avg = reviews.map((m) => m['rating'] as double).reduce((a, b) => a + b) / reviews.length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              const Text("Average Mentor Rating", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80, height: 80,
                    child: CircularProgressIndicator(
                      value: avg / 5,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      color: Colors.amber,
                    ),
                  ),
                  Text(avg.toStringAsFixed(1), 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }  
}