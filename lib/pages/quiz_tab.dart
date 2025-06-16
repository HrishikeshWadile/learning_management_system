import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learning_management_system/pages/quiz_detail_page.dart';

import 'add_quiz_page.dart';

class QuizTab extends StatefulWidget {
  final String classId;

  const QuizTab({super.key, required this.classId});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  bool _isCreator = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsCreator();
  }

  Future<void> _checkIfUserIsCreator() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();
    final data = doc.data();
    if (data != null && data['creator'] == currentUser.uid) {
      setState(() {
        _isCreator = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isCreator = false;
        _isLoading = false;
      });
    }
  }

  void _deleteQuiz(String quizId) {
    FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('quizes')
        .doc(quizId)
        .delete();
  }

  void _navigateToAddQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuizPage(classId: widget.classId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('quizes')
            .snapshots(),
        builder: (context, quizSnapshot) {
          if (quizSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!quizSnapshot.hasData || quizSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No quizzes available."));
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: quizSnapshot.data!.docs.map((quizDoc) {
                final quizData = quizDoc.data() as Map<String, dynamic>;
                final quizRef = quizDoc.reference;
                final quizId = quizDoc.id;

                return StreamBuilder<QuerySnapshot>(
                  stream: quizRef
                      .collection('submissions')
                      .where('userId',
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, subSnap) {
                    final bool withMarks = quizData['withMarks'] ?? true;
                    int? totalScore;
                    if (subSnap.hasData && subSnap.data!.docs.isNotEmpty) {
                      final sub = subSnap.data!.docs.first.data()
                          as Map<String, dynamic>;
                      totalScore =
                          (sub['autoScore'] ?? 0) + (sub['manualScore'] ?? 0);
                    }

                    return Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          title: Text(quizData['title'] ?? 'No Title'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(quizData['description'] ?? ''),
                              if (totalScore != null && withMarks)
                                Text('Your score: $totalScore',
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizDetailPage(
                                  classId: widget.classId,
                                  quizId: quizId,
                                  quizTitle: quizData['title'] ?? 'Quiz',
                                  quizRef: quizRef,
                                ),
                              ),
                            );
                          },
                          trailing: _isCreator
                              ? IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteQuiz(quizId),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: _isCreator
          ? FloatingActionButton(
              onPressed: () => _navigateToAddQuiz(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
