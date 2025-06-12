import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learning_management_system/auth/auth_service.dart';
import 'package:learning_management_system/auth/login_page.dart';

import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = 'settings';
  static const String route = '/settings';
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 36),
        centerTitle: true,
        title: const Text("LMS"),
        backgroundColor: Colors.orangeAccent,
        actions: [
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
    );
  }
}
