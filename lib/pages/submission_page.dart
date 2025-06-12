import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubmissionPage extends StatelessWidget {
  final DocumentReference quizRef;

  const SubmissionPage({super.key, required this.quizRef});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submissions")),
      body: StreamBuilder<QuerySnapshot>(
        stream: quizRef.collection('submissions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['username'] ?? 'Unknown'),
                subtitle: Text(data['answers']?.toString() ?? 'No answers'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
