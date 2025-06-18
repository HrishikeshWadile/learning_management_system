import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuizSubmissionPage extends StatefulWidget {
  final DocumentReference quizRef;
  const QuizSubmissionPage({super.key, required this.quizRef});

  @override
  State<QuizSubmissionPage> createState() => _QuizSubmissionPageState();
}

class _QuizSubmissionPageState extends State<QuizSubmissionPage> {
  final _answers = <DocumentReference, dynamic>{};
  bool _alreadySubmitted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAlreadySubmitted();
  }

  Future<void> _checkAlreadySubmitted() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await widget.quizRef
        .collection('submissions')
        .where('userId', isEqualTo: userId)
        .get();
    setState(() {
      _alreadySubmitted = snapshot.docs.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser!;
    final questionDocs = await widget.quizRef.collection('questions').get();
    int autoScore = 0;

    for (final doc in questionDocs.docs) {
      final data = doc.data();
      final type = data['type'];
      final correct = data['correct_answer'];
      final marks = (data['marks'] ?? 1) as int;
      final userAns = _answers[doc.reference];

      if (type == 'MCQ' && userAns == correct) autoScore += marks;
      if (type == 'MSQ' &&
          userAns is List &&
          correct is List &&
          Set.from(userAns).containsAll(correct) &&
          Set.from(correct).containsAll(userAns)) {
        autoScore += marks;
      }
      if (type == 'Short' &&
          userAns.toString().trim().toLowerCase() ==
              correct.toString().trim().toLowerCase()) {
        autoScore += marks;
      }
      if (type == 'Numerical') {
        if (correct is num && userAns == correct) autoScore += marks;
        if (correct is Map &&
            correct['min'] != null &&
            correct['max'] != null &&
            userAns is num &&
            userAns >= correct['min'] &&
            userAns <= correct['max']) {
          autoScore += marks;
        }
      }
    }

    await widget.quizRef.collection('submissions').add({
      'userId': user.uid,
      'userName': user.displayName,
      'userPhoto': user.photoURL,
      'answers': _answers.entries
          .map((e) => {'questionRef': e.key, 'answer': e.value})
          .toList(),
      'autoScore': autoScore,
      'manualScore': 0,
      'evaluated': !questionDocs.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['type'] == 'Long';
      }),
      'submittedAt': Timestamp.now()
    });

    if (mounted) {
      setState(() => _alreadySubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted Successfully!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_alreadySubmitted) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz Submission")),
        body:
            const Center(child: Text("You have already submitted this quiz.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Answer Quiz")),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.quizRef.collection('questions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final docs = snapshot.data!.docs;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'];
                    final options = List<String>.from(data['options'] ?? []);
                    final marks = data['marks'] ?? 1;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(data['question'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$marks marks',
                                    style:
                                        TextStyle(color: Colors.green.shade800),
                                  ),
                                ),
                              ],
                            ),
                            if (type == 'MCQ')
                              ...options.map((opt) => RadioListTile(
                                    title: Text(opt),
                                    value: opt,
                                    groupValue: _answers[doc.reference],
                                    onChanged: (val) => setState(
                                        () => _answers[doc.reference] = val),
                                  )),
                            if (type == 'MSQ')
                              ...options.map((opt) => CheckboxListTile(
                                    title: Text(opt),
                                    value: (_answers[doc.reference] ?? [])
                                        .contains(opt),
                                    onChanged: (val) {
                                      final current = List<String>.from(
                                          _answers[doc.reference] ?? []);
                                      if (val == true) {
                                        current.add(opt);
                                      } else {
                                        current.remove(opt);
                                      }
                                      setState(() =>
                                          _answers[doc.reference] = current);
                                    },
                                  )),
                            if (type == 'Short' ||
                                type == 'Long' ||
                                type == 'Numerical')
                              TextFormField(
                                decoration:
                                    const InputDecoration(labelText: "Answer"),
                                onChanged: (val) {
                                  _answers[doc.reference] = type == 'Numerical'
                                      ? num.tryParse(val) ?? val
                                      : val;
                                },
                                keyboardType: type == 'Numerical'
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true)
                                    : TextInputType.text,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text("Submit Quiz"),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
