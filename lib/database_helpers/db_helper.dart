import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DBHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload file to Firebase Storage and return the download URL
  Future<String> uploadFile(File file) async {
    try {
      // Ensure file exists
      if (!file.existsSync()) {
        throw Exception("File does not exist at path: ${file.path}");
      }

      // Generate a unique path in Firebase Storage
      final String fileName = file.path.split('/').last;
      final String storagePath =
          'notes/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Upload
      final ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(file);

      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Upload failed. State: ${snapshot.state}');
      }
    } catch (e) {
      throw Exception('Firebase upload error: $e');
    }
  }

  /// Save notes (file-based content) to Firestore
  Future<void> saveNotes({
    required String classId,
    required String title,
    required String description,
    required String fileUrl,
    required String fileId,
  }) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('uploads')
        .add({
      'title': title,
      'description': description,
      'type': 'notes',
      'fileUrl': fileUrl,
      'fileId': fileId,
      'timestamp': DateTime.now(),
    });
  }

  /// Save YouTube video metadata to Firestore
  Future<void> saveVideo({
    required String classId,
    required String title,
    required String description,
    required String youtubeLink,
  }) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('uploads')
        .add({
      'title': title,
      'description': description,
      'type': 'videos',
      'youtubeLink': youtubeLink,
      'timestamp': DateTime.now(),
    });
  }
}

class VideoAndNotesModel {
  String title;
  String description;
  String type; // 'videos' or 'notes'
  String? youtubeLink;
  String? fileUrl;
  DateTime timestamp;

  VideoAndNotesModel({
    required this.title,
    required this.description,
    required this.type,
    this.youtubeLink,
    this.fileUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'youtubeLink': youtubeLink,
      'fileUrl': fileUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory VideoAndNotesModel.fromMap(Map<String, dynamic> map) {
    return VideoAndNotesModel(
      title: map['title'],
      description: map['description'],
      type: map['type'],
      youtubeLink: map['youtubeLink'],
      fileUrl: map['fileUrl'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
