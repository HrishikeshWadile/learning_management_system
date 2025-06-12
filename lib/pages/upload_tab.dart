import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learning_management_system/pages/home_page.dart';
import 'package:learning_management_system/pages/settings_page.dart';
import 'package:learning_management_system/providers/app_data_provider.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../auth/login_page.dart';
import 'about_page.dart';

class UploadTab extends StatelessWidget {
  static const String route = '/upload_tab';
  static const String routeName = 'upload_tab';
  final TextEditingController createClassController = TextEditingController();
  final TextEditingController joinClassController = TextEditingController();

  UploadTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 36),
        centerTitle: true,
        title: const Text("LMS"),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            onPressed: () => context.push(SettingsPage.route),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
          IconButton(
            onPressed: () => context.push(AboutPage.route),
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              context.go(LoginPage.route);
              AuthService.logout();
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<AppDataProvider>(
        builder: (context, value, child) => Column(
          children: [
            // Create Class Container
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(), color: Colors.orange.shade100),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: createClassController,
                        decoration: const InputDecoration(
                          labelText: "Class Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // final classId =
                            await createClass(createClassController.text);
                            createClassController.clear();
                            value.setErrorMsg(''); // Clear any previous error
                            _showSuccessDialog(
                                context, "Class Created Successfully!");
                            await Future.delayed(const Duration(seconds: 1));
                            context.go(HomePage.route);
                          } catch (e) {
                            value.setErrorMsg(e.toString());
                          }
                        },
                        child: const Text("Create Class"),
                      ),
                      if (value.errMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.errMsg,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Join Class Container
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(), color: Colors.orange.shade100),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: joinClassController,
                        decoration: const InputDecoration(
                          labelText: "Class ID",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await joinClass(joinClassController.text);
                            joinClassController.clear();
                            value.setErrorMsg(''); // Clear any previous error
                            _showSuccessDialog(
                                context, "Class Joined Successfully!");
                            await Future.delayed(const Duration(seconds: 1));
                            context.go(HomePage.route);
                          } catch (e) {
                            value.setErrorMsg(e.toString());
                          }
                        },
                        child: const Text("Join Class"),
                      ),
                      if (value.errMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.errMsg,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> createClass(String className) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    String? classId;
    bool isUnique = false;

    // Generate a unique 7-digit alphanumeric ID
    while (!isUnique) {
      classId = _generateAlphanumericId(7);
      isUnique = await _isClassIdUnique(firestore, classId);
    }

    // Create a new class document with the custom ID
    await firestore.collection('classes').doc(classId).set({
      'className': className,
      'creator': user.uid,
      'userIDs': [user.uid],
    });

    // Return the custom class ID
    return classId;
  }

  // Helper function to generate a random alphanumeric ID
  String _generateAlphanumericId(int length) {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Function to check if the class ID is unique
  Future<bool> _isClassIdUnique(
      FirebaseFirestore firestore, String classId) async {
    final doc = await firestore.collection('classes').doc(classId).get();
    return !doc.exists; // Return true if the ID is unique
  }

  Future<void> joinClass(String classId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    // Fetch the class document
    final DocumentSnapshot classDoc =
        await firestore.collection('classes').doc(classId).get();

    if (!classDoc.exists) {
      throw Exception("Class does not exist");
    }

    final Map<String, dynamic> classData =
        classDoc.data() as Map<String, dynamic>;

    // Check if the user is the creator of the class
    if (classData['creator'] == user.uid) {
      throw Exception(
          "You are the creator of this class and cannot join as a student");
    }

    // Check if the user is already in the studentIds array
    final List<dynamic> studentIds = classData['userIDs'] ?? [];
    if (studentIds.contains(user.uid)) {
      throw Exception("You are already a member of this class");
    }

    // Add the user's ID to the studentIds array
    await firestore.collection('classes').doc(classId).update({
      'userIDs': FieldValue.arrayUnion([user.uid]),
    });
  }

  // Helper function to show a success dialog
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
