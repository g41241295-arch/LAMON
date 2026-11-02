/// Konfigurasi URL HTTP Relay untuk Push Notification FCM (Vercel Serverless Function).
///
/// Jika [relayEndpoint] bernilai kosong atau berupa placeholder,
/// [NotificationRelayClient] akan melewati pengiriman relay secara diam-diam
/// tanpa menimbulkan error bagi pengguna.
class NotificationConfig {
  NotificationConfig._();

  /// URL endpoint serverless function relay Vercel.
  /// Contoh: 'https://lamon-notification-relay.vercel.app/api/notify'
  static const String relayEndpoint = '';

  /// Apakah relay endpoint sudah dikonfigurasi secara valid.
  static bool get isConfigured {
    final trimmed = relayEndpoint.trim();
    return trimmed.isNotEmpty &&
        (trimmed.startsWith('https://') || trimmed.startsWith('http://')) &&
        !trimmed.contains('YOUR_VERCEL_APP_URL');
  }
}
