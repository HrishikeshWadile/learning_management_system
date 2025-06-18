import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:learning_management_system/pages/submission_detail_page.dart';

class SubmissionPage extends StatelessWidget {
  final DocumentReference quizRef;
  const SubmissionPage({super.key, required this.quizRef});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submissions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: quizRef.collection('submissions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final submissions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission =
                  submissions[index].data() as Map<String, dynamic>;
              final userName = submission['userName'] ?? 'Unknown';
              final userPhoto = submission['userPhoto'] ?? '';
              final autoScore = submission['autoScore'] ?? 0;
              final manualScore = submission['manualScore'] ?? 0;
              final evaluated = submission['evaluated'] ?? false;
              final total = autoScore + manualScore;
              final timestamp = submission['submittedAt'] as Timestamp?;
              final dateTime = timestamp?.toDate();

              final bgColor = evaluated ? Colors.green : Colors.yellow;

              return Card(
                margin: const EdgeInsets.all(8),
                color: bgColor.shade100,
                child: ListTile(
                  leading:
                      CircleAvatar(backgroundImage: NetworkImage(userPhoto)),
                  title: Text(userName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: $total marks'),
                      if (dateTime != null)
                        Text(
                          'Submitted: ${dateTime.toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: evaluated
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.warning, color: Colors.orange),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmissionDetailPage(
                          submissionData: submission,
                          submissionRef: submissions[index].reference,
                          quizRef: quizRef,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
//
// class QuizSubmissionPage extends StatefulWidget {
//   final DocumentReference quizRef;
//   const QuizSubmissionPage({super.key, required this.quizRef});
//
//   @override
//   State<QuizSubmissionPage> createState() => _QuizSubmissionPageState();
// }
//
// class _QuizSubmissionPageState extends State<QuizSubmissionPage> {
//   final _answers = <DocumentReference, dynamic>{};
//   bool _alreadySubmitted = false;
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkAlreadySubmitted();
//   }
//
//   Future<void> _checkAlreadySubmitted() async {
//     final userId = FirebaseAuth.instance.currentUser!.uid;
//     final snapshot = await widget.quizRef
//         .collection('submissions')
//         .where('userId', isEqualTo: userId)
//         .get();
//     setState(() {
//       _alreadySubmitted = snapshot.docs.isNotEmpty;
//       _loading = false;
//     });
//   }
//
//   Future<void> _submit() async {
//     final user = FirebaseAuth.instance.currentUser!;
//     final questionDocs = await widget.quizRef.collection('questions').get();
//     int autoScore = 0;
//
//     for (final doc in questionDocs.docs) {
//       final data = doc.data();
//       final type = data['type'];
//       final correct = data['correct_answer'];
//       final marks = (data['marks'] ?? 1) as int;
//       final userAns = _answers[doc.reference];
//
//       if (type == 'MCQ' && userAns == correct) autoScore += marks;
//       if (type == 'MSQ' &&
//           userAns is List &&
//           correct is List &&
//           Set.from(userAns).containsAll(correct) &&
//           Set.from(correct).containsAll(userAns)) {
//         autoScore += marks;
//       }
//       if (type == 'Short' &&
//           userAns.toString().trim().toLowerCase() ==
//               correct.toString().trim().toLowerCase()) {
//         autoScore += marks;
//       }
//       if (type == 'Numerical') {
//         if (correct is num && userAns == correct) autoScore += marks;
//         if (correct is Map &&
//             correct['min'] != null &&
//             correct['max'] != null &&
//             userAns is num &&
//             userAns >= correct['min'] &&
//             userAns <= correct['max']) {
//           autoScore += marks;
//         }
//       }
//     }
//
//     await widget.quizRef.collection('submissions').add({
//       'userId': user.uid,
//       'userName': user.displayName,
//       'userPhoto': user.photoURL,
//       'answers': _answers.entries
//           .map((e) => {'questionRef': e.key, 'answer': e.value})
//           .toList(),
//       'autoScore': autoScore,
//       'manualScore': 0,
//       'evaluated': !questionDocs.docs.any((doc) {
//         final data = doc.data();
//         return data['type'] == 'Long';
//       }),
//       'submittedAt': Timestamp.now()
//     });
//
//     if (mounted) {
//       setState(() => _alreadySubmitted = true);
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Submitted Successfully!')));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) return const Center(child: CircularProgressIndicator());
//     if (_alreadySubmitted) {
//       return const Center(child: Text("You have already submitted this quiz."));
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Answer Quiz")),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: widget.quizRef.collection('questions').snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const CircularProgressIndicator();
//           final docs = snapshot.data!.docs;
//           return Column(
//             children: [
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.all(12),
//                   children: docs.map((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     final type = data['type'];
//                     final options = List<String>.from(data['options'] ?? []);
//
//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       child: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(data['question'] ?? '',
//                                 style: const TextStyle(
//                                     fontSize: 16, fontWeight: FontWeight.bold)),
//                             if (type == 'MCQ')
//                               ...options.map((opt) => RadioListTile(
//                                     title: Text(opt),
//                                     value: opt,
//                                     groupValue: _answers[doc.reference],
//                                     onChanged: (val) => setState(
//                                         () => _answers[doc.reference] = val),
//                                   )),
//                             if (type == 'MSQ')
//                               ...options.map((opt) => CheckboxListTile(
//                                     title: Text(opt),
//                                     value: (_answers[doc.reference] ?? [])
//                                         .contains(opt),
//                                     onChanged: (val) {
//                                       final current = List<String>.from(
//                                           _answers[doc.reference] ?? []);
//                                       if (val == true) {
//                                         current.add(opt);
//                                       } else {
//                                         current.remove(opt);
//                                       }
//                                       setState(() =>
//                                           _answers[doc.reference] = current);
//                                     },
//                                   )),
//                             if (type == 'Short' ||
//                                 type == 'Long' ||
//                                 type == 'Numerical')
//                               TextFormField(
//                                 decoration:
//                                     const InputDecoration(labelText: "Answer"),
//                                 onChanged: (val) {
//                                   _answers[doc.reference] = type == 'Numerical'
//                                       ? num.tryParse(val) ?? val
//                                       : val;
//                                 },
//                                 keyboardType: type == 'Numerical'
//                                     ? const TextInputType.numberWithOptions(
//                                         decimal: true)
//                                     : TextInputType.text,
//                               ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: ElevatedButton(
//                   onPressed: _submit,
//                   child: const Text("Submit Quiz"),
//                 ),
//               )
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
