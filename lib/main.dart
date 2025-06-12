import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:learning_management_system/pages/about_page.dart';
import 'package:learning_management_system/pages/class_detail_page.dart';
import 'package:learning_management_system/pages/home_page.dart';
import 'package:learning_management_system/pages/settings_page.dart';
import 'package:learning_management_system/pages/upload_tab.dart';
import 'package:learning_management_system/pages/upload_videos_and_notes.dart';
import 'package:learning_management_system/providers/app_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: "https://wglilewconhadettbtfm.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndnbGlsZXdjb25oYWRldHRidGZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5OTcwOTMsImV4cCI6MjA2MzU3MzA5M30.4b6G7ffxmdPmxmyQVtX4FSLj26xLprKU4mdyjePSGvY",
  );
  runApp(ChangeNotifierProvider(
      create: (BuildContext context) => AppDataProvider(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      routerConfig: _router,
      builder: EasyLoading.init(),
    );
  }

  final _router = GoRouter(
    initialLocation: HomePage.route,
    routes: [
      GoRoute(
        path: LoginPage.route,
        name: LoginPage.routeName,
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
          path: HomePage.route,
          name: HomePage.routeName,
          builder: (context, state) => HomePage(),
          routes: []),
      GoRoute(
          path: ClassDetailPage.route,
          name: ClassDetailPage.routeName,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return ClassDetailPage(
              className: extra['className'],
              creatorName: extra['creatorName'],
              creatorPhoto: extra['creatorPhoto'],
              classID: extra['classId'],
            );
          }),
      GoRoute(
        path: UploadVideosAndNotes.route,
        name: UploadVideosAndNotes.routeName,
        builder: (context, state) {
          // Extract classId from state.extra
          final extra = state.extra as Map<String, dynamic>;
          return UploadVideosAndNotes(classId: extra['classId']);
        },
      ),
      GoRoute(
        path: AboutPage.route,
        name: AboutPage.routeName,
        builder: (context, state) => AboutPage(),
      ),
      GoRoute(
        path: SettingsPage.route,
        name: SettingsPage.routeName,
        builder: (context, state) => SettingsPage(),
      ),
      GoRoute(
        path: UploadTab.route,
        name: UploadTab.routeName,
        builder: (context, state) => UploadTab(),
      ),
    ],
    redirect: (context, state) async {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) {
        return LoginPage.route;
      }
      return null;
    },
  );
}
