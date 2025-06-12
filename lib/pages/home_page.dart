import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learning_management_system/pages/class_detail_page.dart';
import 'package:learning_management_system/pages/settings_page.dart';
import 'package:learning_management_system/pages/upload_tab.dart';

import '../auth/auth_service.dart';
import '../auth/login_page.dart';
import 'about_page.dart';

class HomePage extends StatelessWidget {
  static const String route = '/home';
  static const String routeName = 'home';
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .where('userIDs', arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No classes found.'));
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classData = classes[index].data() as Map<String, dynamic>;
              final creatorId =
                  classData['userIDs'][0]; // First user is the creator
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(creatorId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  if (userSnapshot.hasError) {
                    return ListTile(
                      title: Text('Error: ${userSnapshot.error}'),
                    );
                  }

                  final userData =
                      userSnapshot.data?.data() as Map<String, dynamic>?;
                  final creatorName = userData?['name'] ?? 'Unknown';
                  final creatorPhoto = userData?['photoURL'];
                  // SecureStorageService.saveClassDetails(classData['className'],
                  //     creatorName, creatorPhoto, classes[index].id);
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: creatorPhoto != null
                            ? NetworkImage(creatorPhoto)
                            : null,
                        child: creatorPhoto == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(classData['className']),
                      subtitle: Text('Created by: $creatorName'),
                      onTap: () {
                        context.push(ClassDetailPage.route, extra: {
                          'className': classData['className'],
                          'creatorName': creatorName,
                          'creatorPhoto': creatorPhoto,
                          'classId': classes[index].id,
                        });
                        // print(classData['className']);
                        // print(creatorName);
                        // print(creatorPhoto);
                        // print(classes[index].id);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        // foregroundColor: Colors.white,
        onPressed: () => context.push(UploadTab.route),
        // backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
