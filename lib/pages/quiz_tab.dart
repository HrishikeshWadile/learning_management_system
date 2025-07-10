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
  // bool autoSubmitQuiz = false;

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

  Future<DateTime?> showDateTimePicker(
      BuildContext context, DateTime? initialDateTime) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _showVisibilityDialog(String quizId, Map<String, dynamic> quizData) {
    bool isVisible = quizData['visibility'] ?? false;
    bool scheduleEnabled =
        quizData['startTime'] != null && quizData['endTime'] != null;

    DateTime? start = (quizData['startTime'] as Timestamp?)?.toDate();
    DateTime? end = (quizData['endTime'] as Timestamp?)?.toDate();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Quiz Visibility Settings"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Visible to Students"),
                  value: isVisible,
                  onChanged: (val) {
                    setState(() {
                      isVisible = val;
                      if (isVisible) {
                        scheduleEnabled = false;
                      }
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text("Schedule Visibility"),
                  value: scheduleEnabled,
                  onChanged: (val) async {
                    if (val) {
                      DateTime now = DateTime.now();
                      if (start == null) {
                        final pickedStart =
                            await showDateTimePicker(context, now);
                        start = pickedStart ?? now;
                      }
                      if (end == null) {
                        final pickedEnd = await showDateTimePicker(
                            context, now.add(const Duration(hours: 1)));
                        end = pickedEnd ?? now.add(const Duration(hours: 1));
                      }
                    }

                    setState(() {
                      scheduleEnabled = val;
                      if (scheduleEnabled) {
                        isVisible =
                            start != null && DateTime.now().isAfter(start!);
                      }
                    });
                  },
                ),
                if (scheduleEnabled) ...[
                  ListTile(
                    title: const Text("Start Date & Time"),
                    subtitle: Text(start?.toString() ?? 'Not set'),
                    onTap: () async {
                      final picked = await showDateTimePicker(context, start);
                      if (picked != null) setState(() => start = picked);
                    },
                  ),
                  ListTile(
                    title: const Text("End Date & Time"),
                    subtitle: Text(end?.toString() ?? 'Not set'),
                    onTap: () async {
                      final picked = await showDateTimePicker(context, end);
                      if (picked != null) setState(() => end = picked);
                    },
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  final quizDoc = FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('quizes')
                      .doc(quizId);

                  await quizDoc.update({
                    'visibility': isVisible,
                    'startTime': scheduleEnabled && start != null
                        ? Timestamp.fromDate(start!)
                        : null,
                    'endTime': scheduleEnabled && end != null
                        ? Timestamp.fromDate(end!)
                        : null,
                    'scheduledVisibility': scheduleEnabled,
                  });

                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
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

          final now = DateTime.now();
          final List<DocumentSnapshot> visibleQuizzes = _isCreator
              ? quizSnapshot.data!.docs
              : quizSnapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final start = (data['startTime'] as Timestamp?)?.toDate();
                  final end = (data['endTime'] as Timestamp?)?.toDate();

                  final visible = data['visibility'] == true &&
                      (start == null || now.isAfter(start)) &&
                      (end == null || now.isBefore(end));

                  return visible;
                }).toList();

          if (!_isCreator && visibleQuizzes.isEmpty) {
            return const Center(child: Text("No quizzes available."));
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: visibleQuizzes.map((quizDoc) {
                final quizData = quizDoc.data() as Map<String, dynamic>;
                final quizRef = quizDoc.reference;
                final quizId = quizDoc.id;

                final now = DateTime.now();
                final start = (quizData['startTime'] as Timestamp?)?.toDate();
                final end = (quizData['endTime'] as Timestamp?)?.toDate();
                final isVisible = quizData['visibility'] ?? false;
                final isOpen = (start == null || now.isAfter(start)) &&
                    (end == null || now.isBefore(end));
                final showToStudent = isVisible;

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

                      final int autoScore = sub['autoScore'] ?? 0;
                      final int manualScore = sub['manualScore'] ?? 0;
                      totalScore = autoScore + manualScore;
                    }

                    if (_isCreator) {
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
                                // if (withMarks)
                                // Text('Your score: $totalScore',
                                //     style: TextStyle(
                                //         color: quizData['evaluated'] == true
                                //             ? Colors.green
                                //             : Colors.orange,
                                //         fontWeight: FontWeight.bold)),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    _showVisibilityDialog(quizId, quizData);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteQuiz(quizId),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else if (showToStudent) {
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
                                if (!isOpen &&
                                    start != null &&
                                    now.isBefore(start))
                                  Text("Opens at: ${start.toLocal()}",
                                      style: const TextStyle(
                                          color: Colors.orange)),
                                if (!isOpen && end != null && now.isAfter(end))
                                  Text("Closed on: ${end.toLocal()}",
                                      style:
                                          const TextStyle(color: Colors.red)),
                                if (totalScore != null && withMarks)
                                  Text(
                                    'Your score: $totalScore',
                                    style: TextStyle(
                                        color: quizData['evaluated'] == true
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            enabled: isOpen,
                            onTap: isOpen
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizDetailPage(
                                          classId: widget.classId,
                                          quizId: quizId,
                                          quizTitle:
                                              quizData['title'] ?? 'Quiz',
                                          quizRef: quizRef,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
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

  void _navigateToAddQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuizPage(classId: widget.classId),
      ),
    );
  }
}
