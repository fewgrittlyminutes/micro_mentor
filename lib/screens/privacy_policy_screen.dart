import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy & Data"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF006837),
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Usage Policy", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF006837))
            ),
            SizedBox(height: 10),
            Text("Last Updated: March 2026", style: TextStyle(color: Colors.grey)),
            Divider(height: 40),
            
            _PolicySection(
              title: "1. Data Collection",
              content: "We only collect information necessary for mentorship: your NSBM student email, full name, and any profile details you provide (Bio, Skills, Rates).",
            ),
            _PolicySection(
              title: "2. Secure Authentication",
              content: "Login is handled exclusively through Microsoft OAuth. MicroMentor 2.0 does not see, store, or have access to your NSBM password.",
            ),
            _PolicySection(
              title: "3. Information Sharing",
              content: "Your profile is only visible to other registered NSBM students. Mentors' contact details are only shared once a session request is accepted.",
            ),
            _PolicySection(
              title: "4. Data Deletion",
              content: "Students can request to have their account data removed by contacting the system administrator.",
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }
}