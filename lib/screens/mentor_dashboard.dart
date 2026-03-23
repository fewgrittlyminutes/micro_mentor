import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});
  
  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentor Tools"),
        actions: [
          _buildNotificationIcon(user?.email),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(role: 'mentor'),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Performance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            _buildMentorStats(user?.email ?? ""),

            const SizedBox(height: 30),
            const Text("Student Reviews", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _buildVerticalReviews(user?.email ?? ""),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorStats(String mentorEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('mentorEmail', isEqualTo: mentorEmail.toLowerCase().trim())
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        int totalSessions = snapshot.hasData ? snapshot.data!.docs.length : 0;
        double revenue = totalSessions * 1000.0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('mentorEmail', isEqualTo: mentorEmail.toLowerCase().trim())
              .snapshots(),
          builder: (context, reviewSnapshot) {
            double avgRating = 0.0;
            if (reviewSnapshot.hasData && reviewSnapshot.data!.docs.isNotEmpty) {
              double sum = 0;
              for (var doc in reviewSnapshot.data!.docs) {
                sum += (doc['rating'] ?? 0);
              }
              avgRating = sum / reviewSnapshot.data!.docs.length;
            }
            return _buildStatsUI(totalSessions, avgRating, revenue);
          },
        );
      },
    );
  }

  Widget _buildStatsUI(int sessions, double rating, double revenue) {
    return Row(
      children: [
        _statBox("Sessions", sessions.toString(), Colors.blue),
        const SizedBox(width: 10),
        _statBox("Rating", rating.toStringAsFixed(1), Colors.amber),
        const SizedBox(width: 10),
        _statBox("Revenue", "${revenue.toInt()} LKR", Colors.green),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalReviews(String mentorEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('mentorEmail', isEqualTo: mentorEmail.toLowerCase().trim())
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No reviews yet.", style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var r = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.stars, color: Colors.amber),
                title: Text(r['reviewText'] ?? "No comment"),
                subtitle: Text("Rating: ${r['rating']} Stars"),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildNotificationIcon(String? email) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('mentorEmail', isEqualTo: email?.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        bool hasAlert = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ),
            ),
            if (hasAlert)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }
}