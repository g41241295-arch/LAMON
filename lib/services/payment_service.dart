import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/payment_config.dart';

/// Data hasil pembuatan transaksi Snap Midtrans dari backend.
class SnapTransactionResult {
  final bool success;
  final String orderId;
  final String redirectUrl;
  final String? token;

  const SnapTransactionResult({
    required this.success,
    required this.orderId,
    required this.redirectUrl,
    this.token,
  });

  factory SnapTransactionResult.fromJson(Map<String, dynamic> json) {
    return SnapTransactionResult(
      success: json['success'] == true,
      orderId: json['orderId'] as String? ?? '',
      redirectUrl: json['redirectUrl'] as String? ?? '',
      token: json['token'] as String?,
    );
  }
}

/// Data hasil pemeriksaan status pembayaran dari backend.
class PaymentCheckResult {
  final bool success;
  final String orderId;
  final String paymentStatus;
  final String? rawStatus;

  const PaymentCheckResult({
    required this.success,
    required this.orderId,
    required this.paymentStatus,
    this.rawStatus,
  });

  factory PaymentCheckResult.fromJson(Map<String, dynamic> json) {
    return PaymentCheckResult(
      success: json['success'] == true,
      orderId: json['orderId'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      rawStatus: json['rawStatus'] as String?,
    );
  }
}

/// Service komunikasi ke Backend Pembayaran Midtrans Snap LAMON.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Helper HTTP POST ke backend pembayaran menggunakan HttpClient standar Dart.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const HttpException('User belum login. Silakan login terlebih dahulu.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const HttpException('Gagal mengambil token otentikasi Firebase.');
    }

    final baseUrl = PaymentConfig.cleanBaseUrl;
    final uri = Uri.parse('$baseUrl$path');

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.write(jsonEncode(body));

      final response = await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();

      Map<String, dynamic> data = {};
      try {
        if (responseBody.isNotEmpty) {
          data = jsonDecode(responseBody) as Map<String, dynamic>;
        }
      } catch (_) {}

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      final errorMsg = data['error'] as String? ??
          'Terjadi kesalahan server pembayaran (kode: ${response.statusCode}).';
      throw HttpException(errorMsg);
    } on SocketException catch (e) {
      debugPrint('[PaymentService] SocketException: $e');
      throw const HttpException(
        'Gagal terhubung ke server pembayaran. Pastikan backend aktif atau periksa koneksi internet.',
      );
    } on TimeoutException {
      throw const HttpException('Waktu koneksi ke server pembayaran habis. Coba lagi.');
    } finally {
      client.close();
    }
  }

  /// Meminta backend membuat transaksi Snap Midtrans untuk sebuah konsultasi.
  Future<SnapTransactionResult> createTransaction({
    required String consultationId,
  }) async {
    try {
      final data = await _post('/api/create-transaction', {
        'consultationId': consultationId,
      });

      return SnapTransactionResult.fromJson(data);
    } catch (e) {
      debugPrint('[PaymentService] Error createTransaction: $e');
      rethrow;
    }
  }

  /// Meminta backend mengecek status transaksi ke Midtrans dan sinkronisasi ke Firestore.
  Future<PaymentCheckResult> checkPaymentStatus({
    required String consultationId,
  }) async {
    try {
      final data = await _post('/api/check-payment', {
        'consultationId': consultationId,
      });

      return PaymentCheckResult.fromJson(data);
    } catch (e) {
      debugPrint('[PaymentService] Error checkPaymentStatus: $e');
      rethrow;
    }
  }

  /// Membuka URL Snap Midtrans menggunakan url_launcher (In-App Browser View).
  Future<bool> openSnapPaymentUrl(String redirectUrl) async {
    final uri = Uri.tryParse(redirectUrl);
    if (uri == null) return false;

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      return true;
    } catch (e) {
      debugPrint('[PaymentService] Gagal meluncurkan URL Snap: $e');
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
