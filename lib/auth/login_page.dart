      import 'dart:io';

      import 'package:cloud_firestore/cloud_firestore.dart';
      import 'package:firebase_auth/firebase_auth.dart';
      import 'package:flutter/foundation.dart';
      import 'package:flutter/material.dart';
      import 'package:flutter_easyloading/flutter_easyloading.dart';
      import 'package:go_router/go_router.dart';
      import 'package:google_sign_in/google_sign_in.dart';
      import 'package:learning_management_system/providers/app_data_provider.dart';
      import 'package:provider/provider.dart';

      import '../pages/about_page.dart';
      import '../pages/home_page.dart';
      import '../pages/settings_page.dart';

      class LoginPage extends StatelessWidget {
        static const String routeName = 'login';
        static const String route = '/';
        final _formKey = GlobalKey<FormState>();
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        static String errMsg = '';

        LoginPage({super.key});

        @override
        Widget build(BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
              centerTitle: true,
              title: const Text("Learning Management System"),
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
              ],
            ),
            body: Consumer<AppDataProvider>(builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(top: 150.0),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView(
                        children: [
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child: TextFormField(
                          //     decoration: const InputDecoration(
                          //         filled: true,
                          //         prefixIcon: Icon(Icons.email),
                          //         labelText: 'Email Address'),
                          //     controller: emailController,
                          //     keyboardType: TextInputType.emailAddress,
                          //   ),
                          // ),
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child: TextFormField(
                          //     obscureText: !provider.visiblePassword,
                          //     decoration: InputDecoration(
                          //         filled: true,
                          //         prefixIcon: const Icon(Icons.password),
                          //         suffix: IconButton(
                          //             onPressed: () {
                          //               provider.togglePasswordVisibility();
                          //             },
                          //             icon: provider.visiblePassword
                          //                 ? const Icon(Icons.visibility)
                          //                 : const Icon(Icons.visibility_off)),
                          //         labelText: 'Password'),
                          //     controller: passwordController,
                          //   ),
                          // ),
                          // if (provider.errMsg.isNotEmpty)
                          //   Padding(
                          //     padding: const EdgeInsets.all(8.0),
                          //     child: Text(
                          //       provider.errMsg,
                          //       style: const TextStyle(color: Colors.red),
                          //     ),
                          //   ),
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child: ElevatedButton(
                          //       onPressed: () => _authenticate(context, provider),
                          //       child: const Text("Submit")),
                          // ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () => _signInWithGoogle(context, provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Sign in with Google",
                                      style: TextStyle(color: Colors.black)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }
        //
        // Future<void> _authenticate(
        //     BuildContext context, AppDataProvider provider) async {
        //   if (_formKey.currentState!.validate()) {
        //     EasyLoading.show(status: "Please Wait");
        //     final email = emailController.text.trim();
        //     final password = passwordController.text.trim();
        //
        //     if (email.isEmpty || password.isEmpty) {
        //       EasyLoading.dismiss();
        //       provider.setErrorMsg("Email and Password are required.");
        //       return;
        //     }
        //
        //     try {
        //       final userCredential = await FirebaseAuth.instance
        //           .signInWithEmailAndPassword(email: email, password: password);
        //       final User? user = userCredential.user;
        //       if (user == null) {
        //         throw FirebaseAuthException(
        //             message: "User authentication Failed", code: "auth_failed");
        //       }
        //       EasyLoading.dismiss();
        //       context.go(HomePage.route);
        //     } on FirebaseAuthException catch (e) {
        //       EasyLoading.dismiss();
        //       provider.setErrorMsg(e.message ?? "Authentication error.");
        //     } catch (e) {
        //       EasyLoading.dismiss();
        //       provider.setErrorMsg("An unexpected error occurred.");
        //     }
        //   }
        // }

        Future<void> _signInWithGoogle(
            BuildContext context, AppDataProvider provider) async {
          EasyLoading.show(status: "Please Wait");

          try {
            UserCredential userCredential;

            if (kIsWeb ||
                Platform.isWindows ||
                Platform.isLinux ||
                Platform.isMacOS) {
              GoogleAuthProvider googleProvider = GoogleAuthProvider();

              googleProvider
                  .addScope('https://www.googleapis.com/auth/contacts.readonly');
              googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

              // Once signed in, return the UserCredential
              userCredential =
                  await FirebaseAuth.instance.signInWithPopup(googleProvider);
            } else {
              // ✅ Android/iOS – use authenticate()
              await GoogleSignIn.instance.initialize();

              final GoogleSignInAccount? googleUser =
                  await GoogleSignIn.instance.authenticate();

              if (googleUser == null) {
                throw FirebaseAuthException(
                  message: "Google Sign-In was cancelled or failed.",
                  code: "google_sign_in_cancelled",
                );
              }

              final GoogleSignInAuthentication googleAuth =
                  await googleUser.authentication;

              if (googleAuth.idToken == null) {
                throw FirebaseAuthException(
                  message: "Missing Google ID token.",
                  code: "missing_id_token",
                );
              }
                                                                
              final credential =
                  GoogleAuthProvider.credential(idToken: googleAuth.idToken);

              userCredential =
                  await FirebaseAuth.instance.signInWithCredential(credential);
            }

            // ✅ Post login: Firebase user logic
            final User? user = userCredential.user;
            if (user == null) {
              throw FirebaseAuthException(
                message: "Google Sign-In failed.",
                code: "google_sign_in_failed",
              );
            }

            await _storeUserData(user);
            provider.setUserId(user.uid);

            final classSnapshot =
                await FirebaseFirestore.instance.collection('classes').get();
            for (var doc in classSnapshot.docs) {
              final classId = doc.id;
              final creatorId = doc.data()['creatorId'];
              if (creatorId != null) {
                provider.setCreatorIdForClass(classId, creatorId);
              }
            }

            EasyLoading.dismiss();
            context.go(HomePage.route);
          } on FirebaseAuthException catch (e) {
            EasyLoading.dismiss();
            provider.setErrorMsg(e.message ?? "Firebase Auth error.");
          } catch (e, st) {
            EasyLoading.dismiss();
            debugPrint("Sign-In Error: $e\n$st");
            provider.setErrorMsg("Unexpected error during Google Sign-In.");
          }
        }

        Future<void> _storeUserData(User user) async {
          final FirebaseFirestore firestore = FirebaseFirestore.instance;

          await firestore.collection('users').doc(user.uid).set({
            'name': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
          }, SetOptions(merge: true)); // Merge to avoid overwriting existing data
        }
      }
