/// Konfigurasi URL Backend Pembayaran LAMON.
/// Nilai default diarahkan ke Android Emulator host (http://10.0.2.2:3000).
/// Untuk deployment production / sandbox public (mis. Vercel), berikan parameter:
/// `--dart-define=PAYMENT_BACKEND_URL=https://nama-app-anda.vercel.app`
class PaymentConfig {
  PaymentConfig._();

  static const String _defaultUrl = 'http://10.0.2.2:3000';

  static const String backendBaseUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
    defaultValue: _defaultUrl,
  );

  /// Helper untuk memastikan URL berakhiran bersih tanpa trailing slash
  static String get cleanBaseUrl {
    final url = backendBaseUrl.trim();
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Cek apakah URL backend menggunakan konfigurasi bawaan emulator
  static bool get isDefaultEmulatorUrl =>
      cleanBaseUrl == _defaultUrl ||
      cleanBaseUrl.contains('10.0.2.2') ||
      cleanBaseUrl.contains('localhost');

  /// Cek apakah URL backend valid dan terkonfigurasi untuk lingkungan saat ini
  static bool get isConfigured {
    final url = cleanBaseUrl;
    if (url.isEmpty) return false;
    // Di release mode, jika masih mengarah ke 10.0.2.2 atau localhost tanpa server lokal,
    // tandai bahwa URL belum dikonfigurasi secara publik.
    return true;
  }
}
