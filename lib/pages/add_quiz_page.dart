import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddQuizPage extends StatefulWidget {
  final String classId;

  const AddQuizPage({super.key, required this.classId});

  @override
  State<AddQuizPage> createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _saveQuiz() async {
    final quizCollection = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('quizes');

    final newQuizRef = quizCollection.doc(); // Auto-generated ID
    await newQuizRef.set({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context); // Go back after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Quiz Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveQuiz,
              child: const Text('Save Quiz'),
            )
          ],
        ),
      ),
    );
  }
}
