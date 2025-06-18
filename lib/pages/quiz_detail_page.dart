import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learning_management_system/pages/quiz_submission_page.dart';
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
  final Map<DocumentReference, TextEditingController> _questionControllers = {};
  final Map<DocumentReference, TextEditingController> _answerControllers = {};
  final Map<String, FocusNode> _answerFocusNodes = {}; // Changed key to String
  final Map<DocumentReference, dynamic> _studentAnswers = {};

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  // Helper to get DocumentReference from String ID for student answers
  DocumentReference _getQuestionRefById(String id) =>
      widget.quizRef.collection('questions').doc(id);

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
    if (_withMarks) {
      _calculateTotalMarks();
    }
    if (!_isCreator) {
      _loadStudentAnswers();
    }
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

  void _loadStudentAnswers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('submissions')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final answers = data?['answers'] as Map<String, dynamic>? ?? {};
      setState(() {
        for (var entry in answers.entries) {
          _studentAnswers[_getQuestionRefById(entry.key)] = entry.value;
        }
      });
    }
  }

  Future<void> _saveStudentAnswerToFirebase(
      String questionId, dynamic answer) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final submissionRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('submissions')
        .doc(user.uid); // One submission per user

    await submissionRef.set({
      'userId': user.uid,
      'userName': user.displayName,
      'userEmail': user.email,
      'answers': {questionId: answer},
      'submittedAt': null, // Or Timestamp.now() if already submitted
    }, SetOptions(merge: true)); // Merge allows updating just one answer
  }

  @override
  void dispose() {
    _titleController?.dispose();
    _descriptionController?.dispose();
    _questionControllers.forEach((_, controller) => controller.dispose());
    _answerControllers.forEach((_, controller) => controller.dispose());
    _answerFocusNodes.forEach((_, node) {
      node.dispose();
    });
    super.dispose();
  }

  void _openSettingsDialog() {
    bool tempShuffle = _shuffle;
    bool tempWithMarks = _withMarks;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Quiz Settings"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Shuffle Questions"),
                  value: tempShuffle,
                  onChanged: (val) {
                    setDialogState(() {
                      tempShuffle = val;
                    });
                    widget.quizRef.update({'shuffle': val});
                  },
                ),
                SwitchListTile(
                  title: const Text("Enable Marks"),
                  value: tempWithMarks,
                  onChanged: (val) {
                    setDialogState(() {
                      tempWithMarks = val;
                    });
                    widget.quizRef.update({'withMarks': val});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _shuffle = tempShuffle;
                    _withMarks = tempWithMarks;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
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
          if (_withMarks)
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
                // final docs = snapshot.data!.docs;
                List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

                // Shuffle questions for non-creators if _shuffle is enabled
                if (!_isCreator && _shuffle) {
                  docs.shuffle();
                }

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
          if (!_isCreator)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.green),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Submission"),
                      content: const Text(
                          "Are you sure you want to submit your answers? You won't be able to edit them after submission."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizSubmissionPage(
                          quizRef: widget.quizRef,
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Submit Quiz",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Replace the _buildAnswerWidget method in quiz_detail_page.dart with this:
  Widget _buildAnswerWidget(String type, Map<String, dynamic> data,
      DocumentReference docRef, bool isCreator) {
    final List<String> options = List<String>.from(data['options'] ?? []);
    final dynamic correctAnswer = data['correct_answer'];
    final int marks = data['marks'] ?? 1;

    Widget marksField = isCreator && _withMarks
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

    if (isCreator) {
      // Creator view - show answer fields
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
                      groupValue: correctAnswer,
                      onChanged: (val) => docRef.update(
                        {'correct_answer': val},
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: options[i],
                        onChanged: (val) {
                          options[i] = val;
                          docRef.update({'options': options});
                        },
                      ),
                    )
                  ],
                );
              }),
            ),
            TextButton.icon(
              onPressed: () {
                options.add('Option ${options.length + 1}');
                docRef.update({'options': options});
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
            _withMarks ? marksField : const SizedBox(),
          ],
        );
      } else if (type == 'MSQ') {
        List<String> selected =
            correctAnswer is List ? List<String>.from(correctAnswer) : [];

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
                      onChanged: (val) {
                        if (val == true) {
                          selected.add(options[i]);
                        } else {
                          selected.remove(options[i]);
                        }
                        docRef.update({'correct_answer': selected});
                      },
                    ),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: options[i],
                        onChanged: (val) {
                          options[i] = val;
                          docRef.update({'options': options});
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
            TextButton.icon(
              onPressed: () {
                options.add('Option ${options.length + 1}');
                docRef.update({'options': options});
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
            _withMarks ? marksField : const SizedBox(),
          ],
        );
      } else if (type == 'Numerical') {
        final num? minValue =
            (correctAnswer is Map && correctAnswer.containsKey('min'))
                ? correctAnswer['min']
                : (correctAnswer is num ? correctAnswer : null);
        final num? maxValue =
            (correctAnswer is Map && correctAnswer.containsKey('max'))
                ? correctAnswer['max']
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
            _withMarks ? marksField : const SizedBox(),
          ],
        );
      } else if (type == 'Short') {
        return Column(
          children: [
            TextFormField(
              initialValue: correctAnswer ?? '',
              decoration: const InputDecoration(labelText: "Correct Answer"),
              onChanged: (val) => docRef.update({'correct_answer': val.trim()}),
            ),
            _withMarks ? marksField : const SizedBox(),
          ],
        );
      } else if (type == 'Long') {
        return _withMarks ? marksField : const SizedBox();
      }
    } else {
      // Student view - show answer input fields

      // TextEditingController controller = _answerControllers.putIfAbsent(
      //   docRef,
      //   () => TextEditingController(
      //       text: _studentAnswers[docRef]?.toString() ?? ''),
      // );

      TextEditingController controller;
      if (_answerControllers.containsKey(docRef)) {
        controller = _answerControllers[docRef]!;
      } else {
        final answer = _studentAnswers[docRef.id]?.toString() ?? '';
        controller = TextEditingController(text: answer);
        _answerControllers[docRef] = controller;
      }

      FocusNode focusNode;
      if (_answerFocusNodes.containsKey(docRef.id)) {
        focusNode = _answerFocusNodes[docRef.id]!;
      } else {
        focusNode = FocusNode();
        focusNode.addListener(() {
          if (!focusNode.hasFocus) {
            final val = controller.text.trim();
            _studentAnswers[docRef] = val;
            _saveStudentAnswerToFirebase(docRef.id, val); // Save with String ID
          }
        });
        _answerFocusNodes[docRef.id] = focusNode; // Use String ID as key
      }

      if (type == 'MCQ') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map((opt) {
            final currentAnswer = _studentAnswers[docRef] as String?;
            return RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: currentAnswer,
              onChanged: (val) {
                if (val != null) {
                  _studentAnswers[docRef] = val;
                  _saveStudentAnswerToFirebase(docRef.id, val);
                }
              },
            );
          }).toList(),
        );
      } else if (type == 'MSQ') {
        List<String> selected = _studentAnswers[docRef] is List
            ? List<String>.from(_studentAnswers[docRef])
            : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map((opt) {
            return CheckboxListTile(
              title: Text(opt),
              value: selected.contains(opt),
              onChanged: (val) {
                if (val == true) {
                  selected.add(opt);
                } else {
                  selected.remove(opt);
                }
                _studentAnswers[docRef] = selected;
                _saveStudentAnswerToFirebase(docRef.id, selected);
              },
            );
          }).toList(),
        );
      } else if (type == 'Numerical') {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Your Answer"),
        );
      } else if (type == 'Short') {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(labelText: "Your Answer"),
        );
      } else if (type == 'Long') {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          maxLines: 5,
          decoration: const InputDecoration(labelText: "Your Answer"),
        );
      }
    }

    return const SizedBox();
  }
}
