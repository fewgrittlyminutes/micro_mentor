import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';
import 'my_requests_screen.dart';

class MenteeDashboard extends StatefulWidget {
  final String role;
  const MenteeDashboard({super.key, required this.role});

  @override
  State<MenteeDashboard> createState() => _MenteeDashboardState();
}

class _MenteeDashboardState extends State<MenteeDashboard> {
  String _searchQuery = "";
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool canApply = widget.role == 'mentee';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Portal"),
        actions: [
          _buildHistoryIcon(user?.email),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(role: widget.role)),
              );
            },
          ),
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
            const Text(
              "Find a Mentor", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 15),

            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search skills (e.g. Java, SQL)",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF006837)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF006837), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('authorized_users')
                    .where('role', isEqualTo: 'mentor')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No mentors found."));
                  }

                  var mentors = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    List skills = data['skills'] ?? [];
                    String bio = (data['bio'] ?? "").toString().toLowerCase();
                    String name = (data['name'] ?? "").toString().toLowerCase();

                    return _searchQuery.isEmpty || 
                           name.contains(_searchQuery) ||
                           bio.contains(_searchQuery) ||
                           skills.any((s) => s.toString().toLowerCase().contains(_searchQuery));
                  }).toList();

                  if (mentors.isEmpty) {
                    return const Center(child: Text("No mentors match your search."));
                  }

                  return ListView.builder(
                    itemCount: mentors.length,
                    itemBuilder: (context, index) {
                      var mentorDoc = mentors[index];
                      var mentorData = mentorDoc.data() as Map<String, dynamic>;
                      String mentorEmail = mentorDoc.id;
                      
                      return _buildMentorCard(mentorData, mentorEmail);
                    },
                  );
                },
              ),
            ),
            
            if (canApply)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF006837),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _submitMentorRequest(context, user?.email),
                  child: const Text("Apply to become a Mentor"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryIcon(String? email) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('menteeEmail', isEqualTo: email?.toLowerCase())
          .where('status', whereIn: ['accepted', 'declined']) 
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasUpdate = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyRequestsScreen()),
                );
              },
            ),
            if (hasUpdate)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> data, String mentorEmail) {
    List skills = data['skills'] ?? [];

    return InkWell(
      onTap: () => _showMentorPreview(data, mentorEmail), 
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFF006837),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['name'] ?? "Anonymous",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    _buildAverageRating(mentorEmail),
                  ],
                ),
                subtitle: Text(
                  data['bio'] ?? "No bio available",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(),
              const Text("Skills:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 5),
              Wrap(
                spacing: 8,
                children: skills.take(3).map((skill) => Chip(
                  label: Text(skill.toString(), style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.green[50],
                  side: BorderSide(color: Colors.green.shade200),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMentorPreview(Map<String, dynamic> data, String mentorEmail) {
    final TextEditingController requestController = TextEditingController();
    List skills = data['skills'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          height: MediaQuery.of(context).size.height * 0.85, 
          child: Column(
            children: [
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: Color(0xFF006837),
                            child: Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? "Anonymous",
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const Text("Verified Mentor",
                                    style: TextStyle(color: Color(0xFF006837), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      
                      const Text("About Me", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(data['bio'] ?? "No bio provided.", style: const TextStyle(fontSize: 16, height: 1.4)),
                      
                      const SizedBox(height: 25),
                      const Text("Expertise", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: skills.map((skill) => Chip(
                          label: Text(skill.toString()),
                          backgroundColor: const Color(0xFF006837).withOpacity(0.1),
                          side: const BorderSide(color: Color(0xFF006837)),
                        )).toList(),
                      ),

                      const SizedBox(height: 25),
                      const Text("Reviews & Ratings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      _buildReviewsSection(mentorEmail),

                      const SizedBox(height: 25),
                      const Text("What do you want to learn?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      TextField(
                        controller: requestController,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: "e.g., I need help with Java...", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: const Color(0xFF006837),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    try {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      String studentEmail = currentUser?.email ?? "";
                      String rawMessage = requestController.text.trim();

                      if (rawMessage.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Empty Request"),
                            content: const Text("Please describe what you want to learn."),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                          ),
                        );
                        return;
                      }

                      await FirebaseFirestore.instance.collection('notifications').add({
                        'mentorEmail': mentorEmail.toLowerCase().trim(),
                        'menteeEmail': studentEmail.toLowerCase().trim(),
                        'menteeName': currentUser?.displayName ?? "A Student",
                        'status': 'pending',
                        'menteeMessage': rawMessage,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent!")));
                      }
                    } catch (e) {
                      print("Error: $e");
                    }
                  },
                  child: const Text("Request a Session", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitMentorRequest(BuildContext context, String? email) async {
    try {
      if (email == null) return;
      await FirebaseFirestore.instance
          .collection('authorized_users')
          .doc(email.toLowerCase())
          .update({'hasRequestedMentor': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Application submitted!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildReviewsSection(String mentorEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('mentorEmail', isEqualTo: mentorEmail.toLowerCase().trim())
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            "No reviews yet. Be the first to learn from this mentor!",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          );
        }

        var reviews = snapshot.data!.docs;

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              var r = reviews[index].data() as Map<String, dynamic>;
              int starCount = (r['rating'] ?? 0).toInt();
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) => Icon(
                        Icons.star,
                        size: 14,
                        color: i < starCount ? Colors.amber : Colors.grey[300],
                      )),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        r['reviewText'] ?? "No comment provided.",
                        style: const TextStyle(fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAverageRating(String mentorEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('mentorEmail', isEqualTo: mentorEmail.toLowerCase().trim())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No ratings yet", style: TextStyle(fontSize: 12, color: Colors.grey));
        }

        var reviews = snapshot.data!.docs;
        double sum = 0;
        for (var doc in reviews) {
          sum += (doc['rating'] ?? 0);
        }
        double average = sum / reviews.length;

        return Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              "${average.toStringAsFixed(1)} (${reviews.length})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF006837)),
            ),
          ],
        );
      },
    );
  }
  }