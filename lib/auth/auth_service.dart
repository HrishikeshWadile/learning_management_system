import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static User? get currentUser => _auth.currentUser;

  static Future<bool> loginAdmin(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return credential.user != null;
  }

  static Future<void> logout() async {
    await _auth.signOut();
    await _secureStorage.deleteAll();
  }

  static Future<void> loadUserData(String email, String userID) async {
    await _secureStorage.write(key: 'email', value: email);
    await _secureStorage.write(key: 'userID', value: userID);
  }
}
