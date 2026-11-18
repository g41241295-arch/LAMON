/// Konfigurasi URL Backend Pembayaran LAMON.
/// Nilai default diarahkan ke Android Emulator host (http://10.0.2.2:3000) atau localhost.
/// Untuk lingkungan rilis / production sandbox, deploy backend (misal ke Vercel)
/// dan berikan parameter:
/// `--dart-define=PAYMENT_BACKEND_URL=https://nama-app-anda.vercel.app`
class PaymentConfig {
  PaymentConfig._();

  static const String backendBaseUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Helper untuk memastikan URL berakhiran bersih tanpa trailing slash
  static String get cleanBaseUrl {
    final url = backendBaseUrl.trim();
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
