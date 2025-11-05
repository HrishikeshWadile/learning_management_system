import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:learning_management_system/pages/upload_videos_and_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isDriveAccessGranted = false;
  DateTime? _lastDriveCheck;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsCreator();
    _loadDriveAccessStatus();
  }

  Future<void> _loadDriveAccessStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final granted = prefs.getBool('driveAccessGranted') ?? false;
    final lastCheckedMillis = prefs.getInt('driveLastChecked');

    if (lastCheckedMillis != null) {
      _lastDriveCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckedMillis);
    }

    final now = DateTime.now();
    final needsCheck = _lastDriveCheck == null ||
        now.difference(_lastDriveCheck!).inHours >= 12;

    if (granted && !needsCheck) {
      setState(() {
        _isDriveAccessGranted = true;
      });
    } else {
      await _verifyDriveAccess();
    }
  }

  Future<void> _verifyDriveAccess() async {
    try {
      final uri = Uri.parse(
        'https://script.google.com/macros/s/AKfycbzu_cXXurvxvXsXKUex52xWc4OmbDf1Rd5tEUSYJSUNyHxUeazmjwl3G0dXaxmWRczKlQ/exec?action=verify',
      );

      final response = await http.get(uri);
      final prefs = await SharedPreferences.getInstance();

      if (response.statusCode == 200) {
        setState(() {
          _isDriveAccessGranted = true;
        });
        await prefs.setBool('driveAccessGranted', true);
      } else {
        setState(() {
          _isDriveAccessGranted = false;
        });
        await prefs.setBool('driveAccessGranted', false);
      }

      await prefs.setInt(
          'driveLastChecked', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("Drive access verify failed: $e");
    }
  }

  Future<void> _checkIfUserIsCreator() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
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
    } catch (e) {
      debugPrint('Firestore error: $e');
      await Future.delayed(const Duration(seconds: 2));
      _checkIfUserIsCreator(); // Retry once after delay
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: _isCreator
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isDriveAccessGranted)
                  FloatingActionButton.extended(
                    onPressed: _requestDriveAccess,
                    icon: const Icon(Icons.lock_open),
                    label: const Text("Grant Drive Access"),
                    heroTag: 'drive_access_btn',
                  ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    context.push(
                      UploadVideosAndNotes.route,
                      extra: {'classId': widget.classId},
                    );
                  },
                  heroTag: 'upload_btn',
                  child: const Icon(Icons.add),
                ),
              ],
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
                                      await _deleteFileFromDrive(
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

  Future<void> _requestDriveAccess() async {
    const authUrl =
        'https://script.google.com/macros/s/AKfycbyzss_JZv5DHmtgWXUHEi5sQlGb9AINbRAj__zVI9ir_27m46L65R-HZ0zjc08M_M1I4w/exec?action=auth';

    try {
      final launched = await launchUrl(Uri.parse(authUrl),
          mode: LaunchMode.externalApplication);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Drive auth URL")),
        );
      }
    } catch (e) {
      debugPrint("Drive auth error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Drive auth error: $e")),
      );
    }
  }

  Future<void> _deleteFileFromDrive(String? fileId) async {
    if (fileId == null || fileId.isEmpty) return;

    final url = Uri.parse(
      'https://script.google.com/macros/s/AKfycbyzss_JZv5DHmtgWXUHEi5sQlGb9AINbRAj__zVI9ir_27m46L65R-HZ0zjc08M_M1I4w/exec'
      '?action=delete&fileId=$fileId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        debugPrint("Deleted successfully: $fileId");
      } else {
        debugPrint("Delete failed: ${response.statusCode}, ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("Error deleting file from Drive: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting file: $e")),
      );
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
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        enableCaption: true,
        isLive: false,
        controlsVisibleAtStart: true,
        disableDragSeek: false,
      ),
    );

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.redAccent,
      ),
      builder: (context, player) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            player,
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = 'https://www.youtube.com/watch?v=$videoId';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text("Open in YouTube"),
              ),
            ),
          ],
        );
      },
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
