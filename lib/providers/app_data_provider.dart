import 'package:flutter/widgets.dart';

class AppDataProvider with ChangeNotifier {
  bool _visiblePassword = false;
  bool _isCreator = false;
  String _errMsg = '';

  // ✅ NEW: Add userId and class-creator mapping
  String _userId = '';
  Map<String, String> _classCreatorMap = {}; // classId -> creatorId

  // Existing getters/setters
  bool get isCreator => _isCreator;
  set isCreator(bool value) {
    _isCreator = value;
    notifyListeners();
  }

  bool get visiblePassword => _visiblePassword;
  String get errMsg => _errMsg;

  void togglePasswordVisibility() {
    _visiblePassword = !_visiblePassword;
    notifyListeners();
  }

  void setErrorMsg(String errMsg) {
    _errMsg = errMsg;
    notifyListeners();
  }

  // ✅ NEW: userId getter/setter
  String get userId => _userId;
  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  // ✅ NEW: Set a creator ID for a specific class
  void setCreatorIdForClass(String classId, String creatorId) {
    _classCreatorMap[classId] = creatorId;
    notifyListeners();
  }

  // ✅ NEW: Get the creator ID of a class
  String? creatorIdForClass(String classId) {
    return _classCreatorMap[classId];
  }

  // ✅ Optional: preload mappings in bulk
  void preloadClassCreators(Map<String, String> classCreators) {
    _classCreatorMap = classCreators;
    notifyListeners();
  }
}
