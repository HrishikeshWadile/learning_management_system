import 'package:flutter/material.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: 15, // Replace with actual data
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Chat Message ${index + 1}'),
            subtitle: Text('Sender: User ${index + 1}'),
          );
        },
      ),
    );
  }
}
