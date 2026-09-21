import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/reflux_prediction_model.dart';

class AppState extends ChangeNotifier {
  UserModel _currentUser = const UserModel(
    name: 'Hanabi',
    email: 'Hanabi00@gmail.com',
  );

  bool _isAuthenticated = false;
  bool _lunchDone = false;
  int _currentNavIndex = 1; // 0 = Chat, 1 = Beranda, 2 = Profile
  List<RefluxPredictionResult> _predictionHistory = [];

  // Pre-registered users: email (lowercase) -> { name, password, hasCompletedScreening, screeningData, predictionHistory }
  final Map<String, Map<String, dynamic>> _registeredUsers = {
    'hanabi00@gmail.com': {
      'name': 'Hanabi',
      'password': 'password123',
      'hasCompletedScreening': true,
      'screeningData': null,
      'predictionHistory': <Map<String, dynamic>>[],
    },
    'user@gmail.com': {
      'name': 'User Lamon',
      'password': 'password123',
      'hasCompletedScreening': true,
      'screeningData': null,
      'predictionHistory': <Map<String, dynamic>>[],
    },
  };

  // State draft screening yang sedang berjalan
  String? _draftGender;
  int _draftDay = 1;
  int _draftMonth = 1;
  int _draftYear = 1990;
  bool? _draftHasHistory;

  String? get draftGender => _draftGender;
  int get draftDay => _draftDay;
  int get draftMonth => _draftMonth;
  int get draftYear => _draftYear;
  bool? get draftHasHistory => _draftHasHistory;

  void setDraftGender(String gender) {
    _draftGender = gender;
    notifyListeners();
  }

  void setDraftBirthDate({int? day, int? month, int? year}) {
    if (day != null) _draftDay = day;
    if (month != null) _draftMonth = month;
    if (year != null) _draftYear = year;
    notifyListeners();
  }

  void setDraftHasHistory(bool hasHistory) {
    _draftHasHistory = hasHistory;
    notifyListeners();
  }

  UserModel get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get lunchDone => _lunchDone;
  int get currentNavIndex => _currentNavIndex;
  List<RefluxPredictionResult> get predictionHistory =>
      List.unmodifiable(_predictionHistory);

  /// Menyimpan hasil prediksi ke riwayat akun pengguna
  void savePredictionResult(RefluxPredictionResult result) {
    _predictionHistory.insert(0, result);
    final normalized = _currentUser.email.trim().toLowerCase();
    if (_registeredUsers.containsKey(normalized)) {
      final historyList = (_registeredUsers[normalized]!['predictionHistory']
              as List<dynamic>? ??
          []);
      historyList.insert(0, result.toJson());
      _registeredUsers[normalized]!['predictionHistory'] = historyList;
    }
    notifyListeners();
  }

  /// Mengambil data snapshot riwayat prediksi berdasarkan ID
  RefluxPredictionResult? getPredictionById(String id) {
    try {
      return _predictionHistory.firstWhere((item) {
        final generatedId = 'pred_${item.createdAt.millisecondsSinceEpoch}';
        return item.id == id || (item.id.isEmpty && generatedId == id) || generatedId == id;
      });
    } catch (_) {
      return null;
    }
  }

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
    final hasScreening = user?['hasCompletedScreening'] as bool? ?? false;
    final screeningData = user?['screeningData'] as Map<String, dynamic>?;
    final rawHistory = user?['predictionHistory'] as List<dynamic>? ?? [];
    _predictionHistory = rawHistory
        .map((item) =>
            RefluxPredictionResult.fromJson(item as Map<String, dynamic>))
        .toList();

    _currentUser = UserModel(
      name: displayName,
      email: email.trim(),
      hasCompletedScreening: hasScreening,
      screeningData: screeningData,
    );
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  /// Register a new user account into the system (screening is initially false)
  bool registerWithEmail(String email, String password, {String? name}) {
    final normalized = email.trim().toLowerCase();
    final displayName = name ?? _extractNameFromEmail(email);

    _registeredUsers[normalized] = {
      'name': displayName,
      'password': password,
      'hasCompletedScreening': false,
      'screeningData': null,
      'predictionHistory': <Map<String, dynamic>>[],
    };

    // Reset draft screening
    _draftGender = null;
    _draftDay = 1;
    _draftMonth = 1;
    _draftYear = 1990;
    _draftHasHistory = null;
    _predictionHistory = [];

    _currentUser = UserModel(
      name: displayName,
      email: email.trim(),
      hasCompletedScreening: false,
      screeningData: null,
    );
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  /// Menyelesaikan skrining awal dan menyimpan status ke backend/database akun user.
  /// Mengembalikan true jika berhasil disimpan ke Firestore, false jika gagal.
  Future<bool> completeScreening() async {
    final normalized = _currentUser.email.trim().toLowerCase();
    final data = {
      'gender': _draftGender ?? 'Pria',
      'birthDate': '$_draftYear-${_draftMonth.toString().padLeft(2, '0')}-${_draftDay.toString().padLeft(2, '0')}',
      'hasHistory': _draftHasHistory ?? false,
      'completedAt': DateTime.now().toIso8601String(),
    };

    if (_registeredUsers.containsKey(normalized)) {
      _registeredUsers[normalized]!['hasCompletedScreening'] = true;
      _registeredUsers[normalized]!['screeningData'] = data;
    } else {
      _registeredUsers[normalized] = {
        'name': _currentUser.name,
        'password': '',
        'hasCompletedScreening': true,
        'screeningData': data,
        'predictionHistory': <Map<String, dynamic>>[],
      };
    }

    _currentUser = _currentUser.copyWith(
      hasCompletedScreening: true,
      screeningData: data,
    );
    notifyListeners();

    // Simpan ke Firestore dan tunggu hasilnya sebelum navigasi
    final saved = await _updateScreeningToFirestore(data);
    return saved;
  }

  /// Menyimpan data skrining ke Firestore. Mengembalikan true jika berhasil.
  Future<bool> _updateScreeningToFirestore(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'hasCompletedScreening': true,
          'screeningData': data,
          'jenis_kelamin': data['gender'],
          'tanggal_lahir': data['birthDate'],
          'riwayat_penyakit_lambung': data['hasHistory'],
        }, SetOptions(merge: true));
        debugPrint('Data skrining berhasil disimpan ke Firestore untuk uid: ${user.uid}');
        return true;
      }
      debugPrint('Tidak ada user yang login, data skrining tidak tersimpan.');
      return false;
    } catch (e) {
      debugPrint('GAGAL menyimpan data skrining ke Firestore: $e');
      return false;
    }
  }

  String _extractNameFromEmail(String email) {
    final namePart = email.split('@').first;
    return namePart.isNotEmpty
        ? namePart[0].toUpperCase() + namePart.substring(1)
        : 'Hanabi';
  }

  void loginWithGoogle(String name, String email) {
    final normalized = email.trim().toLowerCase();
    bool hasScreening = false;
    Map<String, dynamic>? screeningData;
    List<dynamic> rawHistory = [];

    if (!_registeredUsers.containsKey(normalized)) {
      _registeredUsers[normalized] = {
        'name': name,
        'password': '',
        'hasCompletedScreening': false,
        'screeningData': null,
        'predictionHistory': <Map<String, dynamic>>[],
      };
    } else {
      hasScreening = _registeredUsers[normalized]!['hasCompletedScreening'] as bool? ?? false;
      screeningData = _registeredUsers[normalized]!['screeningData'] as Map<String, dynamic>?;
      rawHistory = _registeredUsers[normalized]!['predictionHistory'] as List<dynamic>? ?? [];
    }

    _predictionHistory = rawHistory
        .map((item) =>
            RefluxPredictionResult.fromJson(item as Map<String, dynamic>))
        .toList();

    _currentUser = UserModel(
      name: name,
      email: email.trim(),
      hasCompletedScreening: hasScreening,
      screeningData: screeningData,
    );
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
