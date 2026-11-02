import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/notification_config.dart';

/// HTTP Client fire-and-forget untuk memanggil Relay Notification FCM (Vercel Serverless Function).
/// Berjalan tanpa menghalangi alur UI atau pengiriman pesan chat.
class NotificationRelayClient {
  NotificationRelayClient._();
  static final NotificationRelayClient instance = NotificationRelayClient._();

  /// Mengirim request notifikasi ke relay secara asynchronous (fire-and-forget).
  ///
  /// - Mengambil Firebase ID Token pengguna yang sedang login.
  /// - POST JSON ke [NotificationConfig.relayEndpoint].
  /// - Timeout 5 detik.
  /// - Menangkap seluruh error tanpa menampilkan error apapun ke pengguna.
  void notify({
    required String patientUid,
    required String consultationId,
  }) {
    // Jalankan secara unawaited di background event loop
    unawaited(_doNotify(patientUid: patientUid, consultationId: consultationId));
  }

  Future<void> _doNotify({
    required String patientUid,
    required String consultationId,
  }) async {
    // 1. Cek konfigurasi relay
    if (!NotificationConfig.isConfigured) {
      debugPrint('[NotificationRelayClient] Relay URL belum dikonfigurasi. Melewati push notification.');
      return;
    }

    // 2. Cek user auth saat ini
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[NotificationRelayClient] Tidak ada user login untuk ID token.');
      return;
    }

    try {
      // 3. Ambil Firebase ID Token terbaru
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        debugPrint('[NotificationRelayClient] Gagal mengambil ID token.');
        return;
      }

      // 4. Kirim HTTP POST dengan timeout 5 detik
      final uri = Uri.parse(NotificationConfig.relayEndpoint.trim());
      final payload = jsonEncode({
        'patientUid': patientUid,
        'consultationId': consultationId,
      });

      if (kIsWeb) {
        // Untuk web (jika dijalankan di Chrome saat testing)
        // Kita gunakan HttpRequest via browser atau HttpClient standar
        debugPrint('[NotificationRelayClient] Web platform: pengiriman relay dilewati.');
        return;
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      try {
        final request = await client.postUrl(uri).timeout(const Duration(seconds: 5));
        request.headers.set('Content-Type', 'application/json; charset=UTF-8');
        request.headers.set('Authorization', 'Bearer $idToken');
        request.write(payload);

        final response = await request.close().timeout(const Duration(seconds: 5));
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint('[NotificationRelayClient] Response (${response.statusCode}): $responseBody');
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      // Tangkap SEMUA error tanpa memunculkan pop-up / SnackBar
      debugPrint('[NotificationRelayClient] Gagal memanggil relay (non-fatal): $e');
    }
  }
}
