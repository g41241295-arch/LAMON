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

  UserModel get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get lunchDone => _lunchDone;
  int get currentNavIndex => _currentNavIndex;

  void loginWithEmail(String email, String password) {
    final namePart = email.split('@').first;
    final capitalized = namePart.isNotEmpty
        ? namePart[0].toUpperCase() + namePart.substring(1)
        : 'Hanabi';

    _currentUser = UserModel(name: capitalized, email: email);
    _isAuthenticated = true;
    notifyListeners();
  }

  void registerWithEmail(String email, String password) {
    final namePart = email.split('@').first;
    final capitalized = namePart.isNotEmpty
        ? namePart[0].toUpperCase() + namePart.substring(1)
        : 'Hanabi';

    _currentUser = UserModel(name: capitalized, email: email);
    _isAuthenticated = true;
    notifyListeners();
  }

  void loginWithGoogle(String name, String email) {
    _currentUser = UserModel(name: name, email: email);
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
