import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        : Padding(
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
                ],
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF006837),
                  ),
                  onPressed: _updateProfile,
                  child: const Text("Save Profile", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
    );
  }
}