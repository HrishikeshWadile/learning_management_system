import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learning_management_system/pages/submission_page.dart';

class QuizDetailPage extends StatefulWidget {
  final String classId;
  final String quizId;
  final String quizTitle;
  final DocumentReference quizRef;

  const QuizDetailPage({
    super.key,
    required this.classId,
    required this.quizId,
    required this.quizTitle,
    required this.quizRef,
  });

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  bool _isCreator = false;
  bool _isLoading = true;
  int _totalMarks = 0;
  bool _shuffle = false;
  bool _withMarks = true;

  TextEditingController? _titleController;
  TextEditingController? _descriptionController;
  Map<DocumentReference, TextEditingController> _questionControllers = {};

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();

    final quizSnapshot = await widget.quizRef.get();
    final quizData = quizSnapshot.data() as Map<String, dynamic>?;

    setState(() {
      _isCreator = (classDoc.data()?['creator'] == currentUser?.uid);
      _titleController = TextEditingController(text: quizData?['title'] ?? '');
      _descriptionController =
          TextEditingController(text: quizData?['description'] ?? '');
      _shuffle = quizData?['shuffle'] ?? false;
      _withMarks = quizData?['withMarks'] ?? true;
      _isLoading = false;
    });

    _calculateTotalMarks();
  }

  Future<void> _calculateTotalMarks() async {
    final questions = await widget.quizRef.collection('questions').get();
    int total = 0;
    for (var q in questions.docs) {
      final marks = (q.data()['marks'] ?? 1);
      total += marks is int ? marks : 0;
    }
    setState(() {
      _totalMarks = total;
    });
  }

  @override
  void dispose() {
    _titleController?.dispose();
    _descriptionController?.dispose();
    _questionControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quiz Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text("Shuffle Questions"),
              value: _shuffle,
              onChanged: (val) {
                setState(() {
                  _shuffle = val;
                });
                widget.quizRef.update({'shuffle': val});
              },
            ),
            SwitchListTile(
              title: const Text("Enable Marks"),
              value: _withMarks,
              onChanged: (val) {
                setState(() {
                  _withMarks = val;
                });
                widget.quizRef.update({'withMarks': val});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleController?.text ?? widget.quizTitle),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Marks: $_totalMarks",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (_isCreator)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: "Quiz Settings",
              onPressed: _openSettingsDialog,
            ),
          if (_isCreator)
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: "View Submissions",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SubmissionPage(quizRef: widget.quizRef),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isCreator)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Quiz Title"),
                    onChanged: (val) {
                      widget.quizRef.update({'title': val.trim()});
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration:
                        const InputDecoration(labelText: "Quiz Description"),
                    maxLines: null,
                    onChanged: (val) {
                      widget.quizRef.update({'description': val.trim()});
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.quizRef.collection('questions').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                _calculateTotalMarks();

                return ListView.builder(
                  itemCount: docs.length + (_isCreator ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isCreator && index == docs.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Add Question"),
                            onPressed: () async {
                              await widget.quizRef.collection('questions').add({
                                'question': '',
                                'type': 'MCQ',
                                'options': ['Option 1'],
                                'correct_answer': '',
                                'createdAt': Timestamp.now(),
                                'marks': 1,
                              });
                            },
                          ),
                        ),
                      );
                    }

                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final selectedType = data['type'] ?? 'MCQ';

                    _questionControllers.putIfAbsent(
                      doc.reference,
                      () => TextEditingController(text: data['question'] ?? ''),
                    );

                    final controller = _questionControllers[doc.reference]!;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isCreator) ...[
                              TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                    labelText: 'Question'),
                                onChanged: (val) {
                                  doc.reference.update({'question': val});
                                },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedType,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'MCQ', child: Text('MCQ')),
                                  DropdownMenuItem(
                                      value: 'MSQ', child: Text('MSQ')),
                                  DropdownMenuItem(
                                      value: 'Short',
                                      child: Text('Short Answer')),
                                  DropdownMenuItem(
                                      value: 'Long',
                                      child: Text('Long Answer')),
                                  DropdownMenuItem(
                                      value: 'Numerical',
                                      child: Text('Numerical')),
                                ],
                                onChanged: (type) {
                                  if (type != null) {
                                    doc.reference.update({'type': type});
                                  }
                                },
                                decoration:
                                    const InputDecoration(labelText: 'Type'),
                              ),
                              const SizedBox(height: 12),
                              _buildAnswerWidget(selectedType, data,
                                  doc.reference, _isCreator),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await doc.reference.delete();
                                    _questionControllers.remove(doc.reference);
                                  },
                                ),
                              )
                            ] else ...[
                              Text("Q: ${data['question'] ?? ''}",
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 4),
                              Text("Type: ${data['type'] ?? ''}",
                                  style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              _buildAnswerWidget(selectedType, data,
                                  doc.reference, _isCreator),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerWidget(String type, Map<String, dynamic> data,
      DocumentReference docRef, bool isCreator) {
    final List<String> options = List<String>.from(data['options'] ?? []);
    final dynamic correct_answer = data['correct_answer'];
    final int marks = data['marks'] ?? 1;

    Widget marksField = isCreator
        ? TextFormField(
            initialValue: marks.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Marks"),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null) {
                docRef.update({'marks': parsed});
              }
            },
          )
        : const SizedBox();

    if (type == 'MCQ') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(options.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: options[i],
                    groupValue: correct_answer,
                    onChanged: isCreator
                        ? (val) => docRef.update({'correct_answer': val})
                        : null,
                  ),
                  isCreator
                      ? SizedBox(
                          width: 100,
                          child: TextFormField(
                            initialValue: options[i],
                            onChanged: (val) {
                              options[i] = val;
                              docRef.update({'options': options});
                            },
                          ),
                        )
                      : Text(options[i]),
                ],
              );
            }),
          ),
          if (isCreator)
            TextButton.icon(
              onPressed: () {
                options.add('Option ${options.length + 1}');
                docRef.update({'options': options});
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          marksField,
        ],
      );
    } else if (type == 'MSQ') {
      List<String> selected =
          correct_answer is List ? List<String>.from(correct_answer) : [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(options.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: selected.contains(options[i]),
                    onChanged: isCreator
                        ? (val) {
                            if (val == true) {
                              selected.add(options[i]);
                            } else {
                              selected.remove(options[i]);
                            }
                            docRef.update({'correct_answer': selected});
                          }
                        : null,
                  ),
                  isCreator
                      ? SizedBox(
                          width: 100,
                          child: TextFormField(
                            initialValue: options[i],
                            onChanged: (val) {
                              options[i] = val;
                              docRef.update({'options': options});
                            },
                          ),
                        )
                      : Text(options[i]),
                ],
              );
            }),
          ),
          if (isCreator)
            TextButton.icon(
              onPressed: () {
                options.add('Option ${options.length + 1}');
                docRef.update({'options': options});
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          marksField,
        ],
      );
    } else if (type == 'Numerical') {
      final num? minValue =
          (correct_answer is Map && correct_answer.containsKey('min'))
              ? correct_answer['min']
              : (correct_answer is num ? correct_answer : null);
      final num? maxValue =
          (correct_answer is Map && correct_answer.containsKey('max'))
              ? correct_answer['max']
              : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Numerical Answer (exact or range)"),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: minValue?.toString() ?? '',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Min / Exact"),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      if (maxValue != null) {
                        docRef.update({
                          'correct_answer': {'min': parsed, 'max': maxValue}
                        });
                      } else {
                        docRef.update({'correct_answer': parsed});
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: maxValue?.toString() ?? '',
                  enabled: minValue != null,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: "Max (optional)"),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && minValue != null) {
                      docRef.update({
                        'correct_answer': {'min': minValue, 'max': parsed}
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          marksField,
        ],
      );
    } else if (type == 'Short') {
      return Column(
        children: [
          TextFormField(
            initialValue: correct_answer ?? '',
            decoration: const InputDecoration(labelText: "Answer (trimmed)"),
            onChanged: (val) => docRef.update(
                {'correct_answer': val.trim()}), // Trimmed directly here
          ),
          marksField,
        ],
      );
    } else if (type == 'Long') {
      return marksField; // No correct answer input, manual checking
    }

    return const SizedBox();
  }
}
