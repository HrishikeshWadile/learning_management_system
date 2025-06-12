import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learning_management_system/pages/settings_page.dart';

import '../auth/auth_service.dart';
import '../auth/login_page.dart';

class AboutPage extends StatelessWidget {
  static const String routeName = 'about';
  static const String route = '/about';
  const AboutPage({super.key});

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
            onPressed: () => context.push(SettingsPage.route),
            icon: const Icon(Icons.settings, color: Colors.white),
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
