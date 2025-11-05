import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../database_helpers/db_helper.dart';

class UploadVideosAndNotes extends StatefulWidget {
  final String classId;

  const UploadVideosAndNotes({super.key, required this.classId});
  static const String route = '/upload-videos-and-notes';
  static const String routeName = 'upload-videos-and-notes';

  @override
  _UploadVideosAndNotesState createState() => _UploadVideosAndNotesState();
}

class _UploadVideosAndNotesState extends State<UploadVideosAndNotes> {
  String? _selectedOption;
  File? _file;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeLinkController = TextEditingController();
  final DBHelper dbHelper = DBHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Video or Notes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButton<String>(
              value: _selectedOption,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOption = newValue!;
                });
              },
              items: <String>['Video', 'Notes']
                  .map((value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedOption == 'Video')
              TextField(
                controller: _youtubeLinkController,
                decoration: const InputDecoration(
                  labelText: 'YouTube Link',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_selectedOption == 'Notes') ...[
              if (_file != null)
                ListTile(
                  leading:
                      const Icon(Icons.insert_drive_file, color: Colors.blue),
                  title: Text(_file!.path.split('/').last),
                  subtitle: const Text('File selected'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _file = null;
                      });
                    },
                  ),
                ),
              ElevatedButton.icon(
                icon: Icon(_file == null ? Icons.upload_file : Icons.edit),
                label:
                    Text(_file == null ? 'Select Notes File' : 'Replace File'),
                onPressed: _pickFile,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadNoteAndSaveLink,
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadNoteAndSaveLink() async {
    if (_selectedOption == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a type and enter title")),
      );
      return;
    }

    try {
      if (_selectedOption == 'Video') {
        if (_youtubeLinkController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a YouTube link')),
          );
          return;
        }

        await dbHelper.saveVideo(
          classId: widget.classId,
          title: _titleController.text,
          description: _descriptionController.text,
          youtubeLink: _youtubeLinkController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video uploaded successfully!")),
        );
        Navigator.pop(context);
      } else if (_selectedOption == 'Notes') {
        if (_file == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a file")),
          );
          return;
        }

        final fileBytes = await _file!.readAsBytes();
        final base64File = base64Encode(fileBytes);
        final mimeType =
            lookupMimeType(_file!.path) ?? 'application/octet-stream';
        final fileName = path.basename(_file!.path);

        final uri = Uri.parse(
          'https://script.google.com/macros/s/AKfycbyzss_JZv5DHmtgWXUHEi5sQlGb9AINbRAj__zVI9ir_27m46L65R-HZ0zjc08M_M1I4w/exec',
        );

        final response = await http.post(uri, body: {
          'action': 'upload',
          'file': base64File,
          'filename': fileName,
          'mimeType': mimeType,
          'title': _titleController.text,
          'description': _descriptionController.text,
        });

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final fileUrl = json['fileUrl'];
          final fileId = json['fileId'];

          await dbHelper.saveNotes(
            classId: widget.classId,
            title: _titleController.text,
            description: _descriptionController.text,
            fileUrl: fileUrl,
            fileId: fileId,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Note uploaded successfully!")),
          );

          _file = null;
          _titleController.clear();
          _descriptionController.clear();
          _youtubeLinkController.clear();
          setState(() {});
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: ${response.body}")),
          );
          print(response.body);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
