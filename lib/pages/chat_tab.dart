import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatTab extends StatefulWidget {
  final String classId;
  const ChatTab({super.key, required this.classId});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _checkIfCreator();
  }

  Future<void> _checkIfCreator() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();

    setState(() {
      _isCreator = classDoc.data()?['creator'] == user.uid;
    });
  }

  void _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _textController.text.trim().isEmpty) return;

    final message = _textController.text.trim();
    _textController.clear();

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('messages')
        .add({
      'name': user.displayName ?? 'Anonymous',
      'email': user.email,
      'uid': user.uid,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Scroll to bottom
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _deleteMessage(DocumentReference messageRef) async {
    await messageRef.delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email;
    final userId = currentUser?.uid;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['email'] == userEmail;
                    final isFromCreator =
                        data['uid'] != null && data['uid'] == data['creator'];
                    final name = data['name'] ?? 'Unknown';
                    final text = data['message'] ?? '';
                    final timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate().toLocal();

                    final canDelete = _isCreator || data['uid'] == userId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: canDelete
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Message?"),
                                    content: Text(
                                        "Are you sure you want to delete this message?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteMessage(doc.reference);
                                        },
                                        child: const Text("Delete",
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isFromCreator
                                ? Colors.green[100]
                                : isMe
                                    ? Colors.blue[100]
                                    : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4.0),
                              Text(text),
                              if (timestamp != null) ...[
                                const SizedBox(height: 4.0),
                                Text(
                                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      fontSize: 10.0, color: Colors.grey[600]),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      color: Theme.of(context).cardColor,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type a message...',
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
