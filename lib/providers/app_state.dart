import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AppState extends ChangeNotifier {
  UserModel _currentUser = const UserModel(
    name: 'Hanabi',
    email: 'Hanabi00@gmail.com',
  );

  bool _isAuthenticated = false;
  bool _lunchDone = false;
  int _currentNavIndex = 1; // 0 = Chat, 1 = Beranda, 2 = Profile

  // Pre-registered users: email (lowercase) -> { name, password }
  final Map<String, Map<String, String>> _registeredUsers = {
    'hanabi00@gmail.com': {
      'name': 'Hanabi',
      'password': 'password123',
    },
    'user@gmail.com': {
      'name': 'User Lamon',
      'password': 'password123',
    },
  };

  UserModel get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get lunchDone => _lunchDone;
  int get currentNavIndex => _currentNavIndex;

  /// Check whether an email is already registered in the system
  bool isEmailRegistered(String email) {
    final normalized = email.trim().toLowerCase();
    return _registeredUsers.containsKey(normalized);
  }

  /// Verify whether the provided password matches the email
  bool verifyPassword(String email, String password) {
    final normalized = email.trim().toLowerCase();
    final user = _registeredUsers[normalized];
    if (user == null) return false;
    return user['password'] == password;
  }

  /// Log in with credentials after verification
  bool loginWithEmail(String email, String password) {
    final normalized = email.trim().toLowerCase();
    final user = _registeredUsers[normalized];
    final displayName = user?['name'] ?? _extractNameFromEmail(email);

    _currentUser = UserModel(name: displayName, email: email.trim());
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  /// Register a new user account into the system
  bool registerWithEmail(String email, String password, {String? name}) {
    final normalized = email.trim().toLowerCase();
    final displayName = name ?? _extractNameFromEmail(email);

    _registeredUsers[normalized] = {
      'name': displayName,
      'password': password,
    };

    _currentUser = UserModel(name: displayName, email: email.trim());
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  String _extractNameFromEmail(String email) {
    final namePart = email.split('@').first;
    return namePart.isNotEmpty
        ? namePart[0].toUpperCase() + namePart.substring(1)
        : 'Hanabi';
  }

  void loginWithGoogle(String name, String email) {
    final normalized = email.trim().toLowerCase();
    if (!_registeredUsers.containsKey(normalized)) {
      _registeredUsers[normalized] = {
        'name': name,
        'password': '',
      };
    }
    _currentUser = UserModel(name: name, email: email.trim());
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void toggleLunchDone() {
    _lunchDone = !_lunchDone;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);
}
