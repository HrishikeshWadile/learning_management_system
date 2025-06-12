import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final _storage = FlutterSecureStorage();

  // Save class details
  static Future<void> saveClassDetails(String className, String creatorName,
      String creatorPhoto, String classID) async {
    await _storage.write(key: 'className', value: className);
    await _storage.write(key: 'creatorName', value: creatorName);
    await _storage.write(key: 'creatorPhoto', value: creatorPhoto);
    await _storage.write(key: 'classID', value: classID);
  }

  // Retrieve class details
  static Future<Map<String, dynamic>> getClassDetails() async {
    final className = await _storage.read(key: 'className');
    final creatorName = await _storage.read(key: 'creatorName');
    final creatorPhoto = await _storage.read(key: 'creatorPhoto');
    final classID = await _storage.read(key: 'classID');

    return {
      'className': className,
      'creatorName': creatorName,
      'creatorPhoto': creatorPhoto,
      'classID': classID,
    };
  }

  // Clear class details
  static Future<void> clearClassDetails() async {
    await _storage.delete(key: 'className');
    await _storage.delete(key: 'creatorName');
    await _storage.delete(key: 'creatorPhoto');
    await _storage.delete(key: 'classID');
  }
}
