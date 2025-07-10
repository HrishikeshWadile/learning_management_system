import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learning_management_system/pages/quiz_tab.dart';
import 'package:learning_management_system/pages/videos_and_notes_tab.dart';

import 'chat_tab.dart';

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
  int _selectedIndex = 0; // Index for bottom navigation bar

  // Bottom navigation bar items
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Initialize the widget options with the classId
    _widgetOptions = <Widget>[
      VideosAndNotesTab(classId: widget.classID), // Pass classId here
      QuizTab(classId: widget.classID),
      ChatTab(
        classId: widget.classID,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // printData(widget.className, widget.creatorName, widget.creatorPhoto,
    //     widget.classID);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Details"),
      ),
      body: Column(
        children: [
          // Top Section: Class Name, Creator Name, and Photo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.creatorPhoto),
                  // child: const Icon(Icons.person),
                ),
                const SizedBox(width: 16),
                Column(
                  // crossAxisAlignment: CrossAxisAlignment.start,
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
                            // Copy class ID to clipboard
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
          const Divider(), // Divider between top section and content
          // Body Content: Based on selected tab
          Expanded(
            child: _widgetOptions[_selectedIndex],
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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

  // void printData(String? className, String? creatorName, String? creatorPhoto,
  //     String? classID) {
  //   print("Class Name: $className");
  //   print("Creator Name: $creatorName");
  //   print("Creator Photo: $creatorPhoto");
  //   print("Class ID: $classID");
  // }
}
