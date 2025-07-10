import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubmissionDetailPage extends StatefulWidget {
  final Map<String, dynamic> submissionData;
  final DocumentReference submissionRef;
  final DocumentReference quizRef;

  const SubmissionDetailPage({
    super.key,
    required this.submissionData,
    required this.submissionRef,
    required this.quizRef,
  });

  @override
  State<SubmissionDetailPage> createState() => _SubmissionDetailPageState();
}

class _SubmissionDetailPageState extends State<SubmissionDetailPage> {
  final Map<DocumentReference, TextEditingController> _markControllers = {};

  @override
  Widget build(BuildContext context) {
    final answers =
        List<Map<String, dynamic>>.from(widget.submissionData['answers'] ?? []);
    final userName = widget.submissionData['userName'] ?? 'Unknown';
    final userPhoto = widget.submissionData['userPhoto'] ?? '';
    final totalScore = widget.submissionData['totalScore'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("$userName's Submission"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final updatedAnswers = answers.map((answer) {
                final questionRef = answer['questionRef'] as DocumentReference;
                final controller = _markControllers[questionRef];
                final marks = int.tryParse(controller?.text ?? '0') ?? 0;
                return {
                  ...answer,
                  'marks': marks,
                };
              }).toList();

              final int totalMarks = updatedAnswers.fold<int>(
                0,
                (sum, a) => sum + ((a['marks'] ?? 0) as int),
              );

              await widget.submissionRef.update({
                'answers': updatedAnswers,
                'totalMarks': totalMarks,
                'evaluated': true,
              });

              // Update local state to reflect changes immediately
              setState(() {
                widget.submissionData['answers'] = updatedAnswers;
                widget.submissionData['totalMarks'] = totalMarks;
                widget.submissionData['evaluated'] = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Submission evaluated!')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: widget.quizRef.collection('questions').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!.docs;
          final questionMap = {
            for (var q in questions)
              q.reference: q.data() as Map<String, dynamic>
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundImage: NetworkImage(userPhoto)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 18)),
                        Text('Total Score: $totalScore',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Answers:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...answers.map((answer) {
                  final questionRef =
                      answer['questionRef'] as DocumentReference;
                  final questionData = questionMap[questionRef]!;
                  final questionText = questionData['question'] ?? '';
                  final type = questionData['type'] ?? 'MCQ';
                  final options =
                      List<String>.from(questionData['options'] ?? []);
                  final correctAnswer = questionData['correct_answer'];
                  final marks = questionData['marks'] ?? 1;
                  final userAnswer = answer['answer'];
                  final obtainedMarks = answer['marks'] ?? 0;

                  _markControllers.putIfAbsent(
                    questionRef,
                    () => TextEditingController(text: obtainedMarks.toString()),
                  );

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
                                child: Text(questionText,
                                    style: const TextStyle(fontSize: 16)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: obtainedMarks == marks
                                      ? Colors.green.shade100
                                      : Colors.yellow.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$obtainedMarks / $marks',
                                  style: TextStyle(
                                    color: obtainedMarks == marks
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (type == 'MCQ' || type == 'MSQ') ...[
                            const Text('Options:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            ...options.map((opt) => Text(opt)),
                            const SizedBox(height: 8),
                          ],
                          const Text('Correct Answer:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          if (type == 'MCQ' || type == 'Short')
                            Text(correctAnswer.toString()),
                          if (type == 'MSQ')
                            Text((correctAnswer as List).join(', ')),
                          if (type == 'Numerical')
                            correctAnswer is Map
                                ? Text(
                                    'Between ${correctAnswer['min']} and ${correctAnswer['max']}')
                                : Text(correctAnswer.toString()),
                          const SizedBox(height: 8),
                          const Text('User Answer:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          if (type == 'MCQ' || type == 'Short')
                            Text(userAnswer.toString()),
                          if (type == 'MSQ')
                            Text((userAnswer as List).join(', ')),
                          if (type == 'Numerical' || type == 'Long')
                            Text(userAnswer.toString()),
                          const SizedBox(height: 8),
                          const Text('Marks:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextFormField(
                            controller: _markControllers[questionRef],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter marks (max $marks)',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
