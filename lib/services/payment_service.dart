import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/payment_config.dart';

/// Exception terstruktur untuk kegagalan layanan pembayaran LAMON.
/// Menampilkan pesan ramah pengguna tanpa label teknis "HttpException:",
/// serta menyertakan kode debug singkat untuk memudahkan diagnosis.
class PaymentException implements Exception {
  final String message;
  final String? debugCode;
  final dynamic originalError;

  const PaymentException({
    required this.message,
    this.debugCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

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
      throw const PaymentException(
        message: 'Sesi akun tidak ditemukan. Silakan login terlebih dahulu.',
        debugCode: 'AUTH_REQUIRED',
      );
    }

    String? idToken;
    try {
      idToken = await user.getIdToken();
    } catch (e) {
      debugPrint('[PaymentService] Gagal mengambil idToken: $e');
      throw PaymentException(
        message: 'Gagal memverifikasi sesi otentikasi. Silakan login kembali.',
        debugCode: 'TOKEN_FETCH_ERROR',
        originalError: e,
      );
    }

    if (idToken == null || idToken.isEmpty) {
      throw const PaymentException(
        message: 'Sesi otentikasi kosong. Silakan login kembali.',
        debugCode: 'TOKEN_EMPTY',
      );
    }

    final baseUrl = PaymentConfig.cleanBaseUrl;
    final fullUrlString = '$baseUrl$path';
    final uri = Uri.tryParse(fullUrlString);

    if (uri == null) {
      throw const PaymentException(
        message: 'Format alamat server pembayaran tidak valid.',
        debugCode: 'INVALID_BASE_URL',
      );
    }

    debugPrint('[PaymentService] Calling endpoint: ${uri.scheme}://${uri.host}:${uri.port}${uri.path}');

    // Peringatan jika di release build masih menggunakan URL default emulator
    if (kReleaseMode && PaymentConfig.isDefaultEmulatorUrl) {
      debugPrint('[PaymentService] WARNING: Build release berjalan dengan default emulator URL ($baseUrl)');
    }

    final client = HttpClient();
    // Beri batas waktu koneksi 25 detik untuk mengakomodasi cold start serverless (Vercel/Render)
    client.connectionTimeout = const Duration(seconds: 25);

    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.write(jsonEncode(body));

      // Beri batas waktu penerimaan response 35 detik
      final response = await request.close().timeout(const Duration(seconds: 35));
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

      final errorMsg = data['error'] as String?;
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw PaymentException(
          message: errorMsg ?? 'Sesi autentikasi telah berakhir. Silakan login kembali.',
          debugCode: 'HTTP_${response.statusCode}',
        );
      } else if (response.statusCode == 404) {
        throw PaymentException(
          message: errorMsg ?? 'Layanan endpoint pembayaran tidak ditemukan.',
          debugCode: 'HTTP_404',
        );
      } else if (response.statusCode >= 500) {
        throw PaymentException(
          message: errorMsg ?? 'Server pembayaran sedang mengalami gangguan teknis.',
          debugCode: 'HTTP_${response.statusCode}',
        );
      } else {
        throw PaymentException(
          message: errorMsg ?? 'Permintaan pembayaran gagal (kode: ${response.statusCode}).',
          debugCode: 'HTTP_${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('[PaymentService] SocketException ($fullUrlString): $e');
      if (kReleaseMode && PaymentConfig.isDefaultEmulatorUrl) {
        throw PaymentException(
          message: 'Alamat server pembayaran belum dikonfigurasi. Hubungi pengembang atau periksa konfigurasi aplikasi.',
          debugCode: 'ERR_URL_NOT_CONFIGURED',
          originalError: e,
        );
      }
      final osMsg = e.osError?.message.toLowerCase() ?? '';
      if (osMsg.contains('refused')) {
        throw PaymentException(
          message: 'Server pembayaran tidak aktif atau tidak dapat dijangkau.',
          debugCode: 'ERR_CONN_REFUSED',
          originalError: e,
        );
      } else if (osMsg.contains('permission denied')) {
        throw PaymentException(
          message: 'Akses koneksi internet diblokir pada perangkat Anda.',
          debugCode: 'ERR_PERMISSION_DENIED',
          originalError: e,
        );
      } else if (osMsg.contains('unreachable') || osMsg.contains('failed host lookup')) {
        throw PaymentException(
          message: 'Tidak ada koneksi internet atau alamat server tidak dapat dihubungi.',
          debugCode: 'ERR_NO_INTERNET',
          originalError: e,
        );
      }
      throw PaymentException(
        message: 'Gagal terhubung ke server pembayaran. Pastikan backend aktif atau periksa koneksi internet.',
        debugCode: 'ERR_SOCKET_${e.osError?.errorCode ?? 'UNKNOWN'}',
        originalError: e,
      );
    } on HandshakeException catch (e) {
      debugPrint('[PaymentService] HandshakeException: $e');
      throw PaymentException(
        message: 'Koneksi aman ke server pembayaran gagal diverifikasi (SSL/TLS).',
        debugCode: 'ERR_SSL_HANDSHAKE',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      debugPrint('[PaymentService] TimeoutException: $e');
      throw PaymentException(
        message: 'Waktu koneksi ke server pembayaran habis. Silakan coba lagi.',
        debugCode: 'ERR_TIMEOUT',
        originalError: e,
      );
    } on PaymentException {
      rethrow;
    } catch (e) {
      debugPrint('[PaymentService] Unexpected error: $e');
      throw PaymentException(
        message: 'Terjadi kendala saat memproses koneksi pembayaran.',
        debugCode: 'ERR_UNEXPECTED',
        originalError: e,
      );
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
