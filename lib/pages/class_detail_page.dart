import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learning_management_system/pages/chat_tab.dart';
import 'package:learning_management_system/pages/quiz_tab.dart';
import 'package:learning_management_system/pages/videos_and_notes_tab.dart';

class ClassDetailPage extends StatefulWidget {
  static const String route = '/class-detail';
  static const String routeName = 'class-detail';

  final String creatorPhoto;
  final String className;
  final String creatorName;
  final String classID;

  const ClassDetailPage({
    super.key,
    required this.creatorPhoto,
    required this.className,
    required this.creatorName,
    required this.classID,
  });

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  int _selectedIndex = 0;

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 0:
        return VideosAndNotesTab(classId: widget.classID);
      case 1:
        return QuizTab(classId: widget.classID);
      case 2:
        return ChatTab(classId: widget.classID);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Details"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.creatorPhoto),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      widget.className,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Created by: ${widget.creatorName}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Text(widget.classID),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: widget.classID));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Class ID copied to clipboard'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(child: _buildSelectedTab()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos & Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
