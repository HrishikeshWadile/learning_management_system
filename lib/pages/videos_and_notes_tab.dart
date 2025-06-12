import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learning_management_system/pages/upload_videos_and_notes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../file_viewers/image_preview_screen.dart';
import '../file_viewers/office_web_viewer.dart';
import '../file_viewers/pdf_viewer.dart';

class VideosAndNotesTab extends StatefulWidget {
  final String classId;

  const VideosAndNotesTab({super.key, required this.classId});

  @override
  State<VideosAndNotesTab> createState() => _VideosAndNotesTabState();
}

class _VideosAndNotesTabState extends State<VideosAndNotesTab> {
  bool _isCreator = false;
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: _isCreator
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                context.push(
                  UploadVideosAndNotes.route,
                  extra: {'classId': widget.classId},
                );
              },
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('uploads')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No videos or notes found.'));
          }

          final uploads = snapshot.data!.docs;

          return ListView.builder(
            itemCount: uploads.length,
            itemBuilder: (context, index) {
              final upload = uploads[index].data() as Map<String, dynamic>;
              final title = upload['title'] ?? 'No Title';
              final description = upload['description'] ?? 'No Description';
              final type = upload['type'];
              final timestamp = upload['timestamp']?.toDate() ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (type == 'videos')
                      _buildVideoPreview(upload['youtubeLink'], context)
                    else if (type == 'notes')
                      _buildNotesPreview(context, upload['fileUrl']),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(title,
                          //     style: const TextStyle(
                          //         fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_isCreator)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text(
                                            "Are you sure you want to delete this file?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text("Delete",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await _deleteFileFromSupabase(
                                          upload['filePath']);
                                      await FirebaseFirestore.instance
                                          .collection('classes')
                                          .doc(widget.classId)
                                          .collection('uploads')
                                          .doc(uploads[index].id)
                                          .delete();
                                    }
                                  },
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Text(description),
                          const SizedBox(height: 8),
                          Text(
                            'Uploaded on: ${_formatTimestamp(timestamp)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteFileFromSupabase(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;

      final fullPath =
          '${widget.classId}/$fileName'; // no need to prefix 'notes/'

      debugPrint("Trying to delete: $fullPath");

      await supabase.storage.from('notes').remove([fullPath]);
      // print(fullPath);

      debugPrint("File deleted successfully from Supabase: $fullPath");
    } catch (e) {
      debugPrint("Error deleting from Supabase: $e");
    }
  }

  Widget _buildVideoPreview(String youtubeLink, BuildContext context) {
    final videoId = YoutubePlayer.convertUrlToId(youtubeLink);
    if (videoId == null) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: Text('Invalid YouTube URL')),
      );
    }

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false),
    );

    return YoutubePlayer(
      controller: controller,
      showVideoProgressIndicator: true,
    );
  }

  Widget _buildNotesPreview(BuildContext context, String fileUrl) {
    final ext = fileUrl.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImagePreviewScreen(imageUrl: fileUrl),
              ));
        },
        child: Image.network(fileUrl,
            height: 200, width: double.infinity, fit: BoxFit.cover),
      );
    }

    if (ext == 'pdf') {
      return ListTile(
        leading: const Icon(Icons.picture_as_pdf),
        title: const Text("Open PDF"),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PDFViewerFromUrl(url: fileUrl),
              ));
        },
      );
    }

    if (['docx', 'pptx', 'xlsx'].contains(ext)) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OfficeWebViewer(url: fileUrl),
              ));
        },
        child: Container(
          height: 150,
          color: Colors.grey[200],
          child: const Center(child: Text("Tap to view document")),
        ),
      );
    }

    return const Text("Unsupported file type");
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}';
  }
}
