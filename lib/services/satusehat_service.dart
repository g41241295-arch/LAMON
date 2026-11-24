import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/payment_config.dart';

/// Hasil verifikasi dan sinkronisasi pasien dengan SatuSehat Kemenkes
class SatuSehatVerificationResult {
  final bool success;
  final String? ihsNumber;
  final String? nik;
  final String? name;
  final String? gender;
  final String? birthDate;
  final String? address;
  final String message;

  const SatuSehatVerificationResult({
    required this.success,
    this.ihsNumber,
    this.nik,
    this.name,
    this.gender,
    this.birthDate,
    this.address,
    required this.message,
  });

  factory SatuSehatVerificationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return SatuSehatVerificationResult(
      success: json['success'] == true,
      ihsNumber: data?['ihsNumber']?.toString(),
      nik: data?['nik']?.toString(),
      name: data?['name']?.toString(),
      gender: data?['gender']?.toString(),
      birthDate: data?['birthDate']?.toString(),
      address: data?['address']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Status integrasi SatuSehat akun pengguna
class SatuSehatStatusResult {
  final bool isLinked;
  final String? ihsNumber;
  final String? nik;
  final String? verifiedName;
  final String? linkedAt;

  const SatuSehatStatusResult({
    required this.isLinked,
    this.ihsNumber,
    this.nik,
    this.verifiedName,
    this.linkedAt,
  });

  factory SatuSehatStatusResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return SatuSehatStatusResult(
      isLinked: data?['isLinked'] == true,
      ihsNumber: data?['ihsNumber']?.toString(),
      nik: data?['nik']?.toString(),
      verifiedName: data?['verifiedName']?.toString(),
      linkedAt: data?['linkedAt']?.toString(),
    );
  }
}

/// Service komunikasi ke endpoint SatuSehat FHIR pada backend LAMON
class SatuSehatService {
  SatuSehatService._();
  static final SatuSehatService instance = SatuSehatService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Helper request HTTP internal
  Future<Map<String, dynamic>> _sendRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Sesi akun tidak ditemukan. Silakan login terlebih dahulu.');
    }

    String? idToken;
    try {
      idToken = await user.getIdToken();
    } catch (e) {
      debugPrint('[SatuSehatService] Gagal mengambil idToken: $e');
    }

    final baseUrl = PaymentConfig.cleanBaseUrl;
    final uri = Uri.tryParse('$baseUrl$path');

    if (uri == null) {
      throw Exception('Format URL backend tidak valid: $baseUrl$path');
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 25);

    try {
      late HttpClientRequest request;
      if (method == 'POST') {
        request = await client.postUrl(uri);
      } else {
        request = await client.getUrl(uri);
      }

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (idToken != null && idToken.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      }

      if (body != null && method == 'POST') {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(const Duration(seconds: 35));
      final responseBody = await response.transform(utf8.decoder).join();

      Map<String, dynamic> data = {};
      if (responseBody.isNotEmpty) {
        try {
          data = jsonDecode(responseBody) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        final errorMsg = data['message'] ??
            data['error'] ??
            'Permintaan gagal dengan status ${response.statusCode}';
        throw Exception(errorMsg);
      }
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server backend. Pastikan backend aktif.',
      );
    } on TimeoutException {
      throw Exception('Waktu tunggu koneksi ke server telah habis (timeout).');
    } finally {
      client.close();
    }
  }

  /// Verifikasi NIK pasien dan tautkan dengan SatuSehat FHIR
  Future<SatuSehatVerificationResult> verifyPatient(String nik) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak valid.');
    }

    final result = await _sendRequest(
      'POST',
      '/api/satusehat/verify-patient',
      body: {
        'uid': user.uid,
        'nik': nik.trim(),
      },
    );

    return SatuSehatVerificationResult.fromJson(result);
  }

  /// Periksa status keterhubungan SatuSehat akun saat ini
  Future<SatuSehatStatusResult> getStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const SatuSehatStatusResult(isLinked: false);
    }

    final result = await _sendRequest(
      'GET',
      '/api/satusehat/patient-status/${user.uid}',
    );

    return SatuSehatStatusResult.fromJson(result);
  }

  /// Putus tautan SatuSehat
  Future<bool> unlinkPatient() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final result = await _sendRequest(
      'POST',
      '/api/satusehat/unlink-patient',
      body: {'uid': user.uid},
    );

    return result['success'] == true;
  }
}
