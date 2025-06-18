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
  bool _evaluated = false;

  @override
  void initState() {
    super.initState();
    _evaluated = widget.submissionData['evaluated'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final answers =
        List<Map<String, dynamic>>.from(widget.submissionData['answers'] ?? []);
    final userName = widget.submissionData['userName'] ?? 'Unknown';
    final userPhoto = widget.submissionData['userPhoto'] ?? '';
    final autoScore = widget.submissionData['autoScore'] ?? 0;
    final manualScore = widget.submissionData['manualScore'] ?? 0;
    final total = autoScore + manualScore;

    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Submission'),
        actions: [
          if (!_evaluated)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                await widget.submissionRef.update({
                  'evaluated': true,
                  'manualScore': _calculateManualScore(),
                });
                setState(() {
                  _evaluated = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submission evaluated!')));
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
                        Text('Total Score: $total',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Auto Score: $autoScore'),
                        Text('Manual Score: $manualScore'),
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
                  final isCorrect =
                      _isAnswerCorrect(type, userAnswer, correctAnswer);
                  final isAutoGraded = type != 'Long';

                  _markControllers.putIfAbsent(
                    questionRef,
                    () => TextEditingController(
                        text:
                            isAutoGraded && isCorrect ? marks.toString() : '0'),
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
                                  color: isAutoGraded && isCorrect
                                      ? Colors.green.shade100
                                      : Colors.yellow.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isAutoGraded && isCorrect
                                      ? '$marks/$marks'
                                      : '-/$marks',
                                  style: TextStyle(
                                    color: isAutoGraded && isCorrect
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
                          if (!isAutoGraded || !_evaluated) ...[
                            const Text('Marks:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextFormField(
                              controller: _markControllers[questionRef],
                              enabled: !_evaluated,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter marks (max $marks)',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter marks';
                                }
                                final numValue = int.tryParse(value);
                                if (numValue == null || numValue > marks) {
                                  return 'Max $marks marks';
                                }
                                return null;
                              },
                            ),
                          ],
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

  bool _isAnswerCorrect(
      String type, dynamic userAnswer, dynamic correctAnswer) {
    if (type == 'MCQ') {
      return userAnswer == correctAnswer;
    } else if (type == 'MSQ') {
      return userAnswer is List &&
          correctAnswer is List &&
          Set.from(userAnswer).containsAll(correctAnswer) &&
          Set.from(correctAnswer).containsAll(userAnswer);
    } else if (type == 'Short') {
      return userAnswer.toString().trim().toLowerCase() ==
          correctAnswer.toString().trim().toLowerCase();
    } else if (type == 'Numerical') {
      if (correctAnswer is num) {
        return userAnswer == correctAnswer;
      } else if (correctAnswer is Map) {
        return userAnswer is num &&
            userAnswer >= correctAnswer['min'] &&
            userAnswer <= correctAnswer['max'];
      }
    }
    return false;
  }

  int _calculateManualScore() {
    int total = 0;
    for (final controller in _markControllers.values) {
      final marks = int.tryParse(controller.text) ?? 0;
      total += marks;
    }
    return total;
  }
}
