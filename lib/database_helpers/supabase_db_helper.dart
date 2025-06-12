// import 'dart:io';
//
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:uuid/uuid.dart';
//
// class SupabaseDBHelper {
//   final SupabaseClient _client = Supabase.instance.client;
//
//   /// Upload file to Supabase Storage and return public URL
//   Future<String> uploadFile(File file) async {
//     if (!file.existsSync()) {
//       throw Exception("File does not exist at path: ${file.path}");
//     }
//
//     final String fileName = '${const Uuid().v4()}_${file.path.split('/').last}';
//     final String filePath = 'notes/$fileName';
//
//     final storageResponse = await _client.storage
//         .from('notes_bucket') // Your bucket name in Supabase
//         .upload(filePath, file);
//
//     if (storageResponse.isEmpty) {
//       throw Exception("Failed to upload file to Supabase");
//     }
//
//     final publicUrl =
//         _client.storage.from('notes_bucket').getPublicUrl(filePath);
//
//     return publicUrl;
//   }
//
//   /// Save Notes to Supabase Table
//   Future<void> saveNotes({
//     required String classId,
//     required String title,
//     required String description,
//     required String fileUrl,
//   }) async {
//     final response = await _client.from('uploads').insert({
//       'class_id': classId,
//       'title': title,
//       'description': description,
//       'type': 'notes',
//       'file_url': fileUrl,
//       'created_at': DateTime.now().toIso8601String(),
//     });
//
//     if (response.error != null) {
//       throw Exception(response.error!.message);
//     }
//   }
//
//   /// Save Video to Supabase Table
//   Future<void> saveVideo({
//     required String classId,
//     required String title,
//     required String description,
//     required String youtubeLink,
//   }) async {
//     final response = await _client.from('uploads').insert({
//       'class_id': classId,
//       'title': title,
//       'description': description,
//       'type': 'videos',
//       'youtube_link': youtubeLink,
//       'created_at': DateTime.now().toIso8601String(),
//     });
//
//     if (response.error != null) {
//       throw Exception(response.error!.message);
//     }
//   }
//
//   /// Fetch uploads (optional: filter by classId)
//   Future<List<Map<String, dynamic>>> getUploads(String classId) async {
//     final response = await _client
//         .from('uploads')
//         .select()
//         .eq('class_id', classId)
//         .order('created_at', ascending: false);
//
//     if (response.error != null) {
//       throw Exception(response.error!.message);
//     }
//
//     return response;
//   }
// }
