import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';


class EditProfileScreen extends StatefulWidget {
  final String role;
  const EditProfileScreen({super.key, required this.role});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final doc = await FirebaseFirestore.instance
        .collection('authorized_users')
        .doc(user?.email?.toLowerCase())
        .get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? user?.displayName ?? '';
        _bioController.text = data['bio'] ?? '';
        _skillsController.text = (data['skills'] as List<dynamic>?)?.join(', ') ?? '';
        _priceController.text = (data['price'] ?? '1000').toString();
        _isLoading = false;
      });
    }
  }

  void _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    Map<String, dynamic> updateData = {
      'name': _nameController.text,
      'bio': _bioController.text,
    };

    if (widget.role == 'mentor') {
      updateData['skills'] = _skillsController.text.split(',').map((e) => e.trim()).toList();
      updateData['price'] = double.tryParse(_priceController.text) ?? 1000.0;
    }

    await FirebaseFirestore.instance
        .collection('authorized_users')
        .doc(user?.email?.toLowerCase())
        .update(updateData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Bio", border: OutlineInputBorder()),
                ),
                if (widget.role == 'mentor') ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: _skillsController,
                    decoration: const InputDecoration(labelText: "Skills (comma separated)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Session Rate (LKR)", 
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: OutlineInputBorder()
                    ),
                  ),
                ],
                const SizedBox(height: 40), 

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF006837),
                  ),
                  onPressed: _updateProfile,
                  child: const Text("Save Profile", style: TextStyle(color: Colors.white)),
                ),
                  
                const SizedBox(height: 30),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Color(0xFF006837)),
                  title: const Text("Contact Support"),
                  subtitle: const Text("Send an email to our team"),
                  onTap: _contactSupport,
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF006837)),
                  title: const Text("Privacy Policy"),
                  subtitle: const Text("View data and privacy terms"),
                  onTap: () => _showPrivacyPolicy(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hhdkweerasinghe@students.nsbm.ac.lk',
      queryParameters: {
        'subject': 'Support Request - MicroMentor 2.0',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "1. Data Collection: We only store your name, bio, and skills.\n\n"
            "2. Authentication: MicroMentor uses Microsoft OAuth. We never see or store your password.\n\n"
            "3. Usage: Your profile is only visible to registered NSBM students.\n\n"
            "4. Support: For data deletion requests, contact support via the email provided.",
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}