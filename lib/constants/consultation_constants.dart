/// Konstanta untuk fitur Konsultasi Dokter.
/// Ubah nilai di sini jika ada perubahan biaya layanan atau format VA.
class ConsultationConstants {
  ConsultationConstants._();

  /// Biaya layanan aplikasi per sesi konsultasi (dalam Rupiah).
  /// TODO(payment-gateway): Ganti dengan nilai dari konfigurasi backend
  /// saat integrasi dengan payment gateway sungguhan (Midtrans/Xendit).
  static const int serviceFee = 10000;

  /// Prefix nomor virtual account untuk simulasi.
  /// TODO(payment-gateway): Hapus dan gunakan VA number dari response
  /// payment gateway sesungguhnya.
  static const String vaPrefix = '88099';

  /// Durasi batas waktu pembayaran (24 jam).
  static const Duration paymentDeadlineDuration = Duration(hours: 24);

  /// Delay simulasi balasan dokter (3 detik setelah pasien kirim pesan).
  /// TODO(chat-realtime): Hapus simulasi ini dan ganti dengan sistem
  /// notifikasi push / WebSocket / Firebase Cloud Messaging untuk
  /// menghubungkan dokter sungguhan.
  static const Duration doctorReplyDelay = Duration(seconds: 3);

  /// Daftar metode pembayaran yang tersedia.
  static const List<PaymentMethodData> paymentMethods = [
    PaymentMethodData(id: 'bsi', name: 'BSI', iconLabel: 'BSI'),
    PaymentMethodData(id: 'mandiri', name: 'Bank Mandiri', iconLabel: 'MANDIRI'),
    PaymentMethodData(id: 'bri', name: 'BRI', iconLabel: 'BRI'),
    PaymentMethodData(id: 'jatim', name: 'Bank Jatim', iconLabel: 'JATIM'),
    PaymentMethodData(id: 'bca', name: 'BCA', iconLabel: 'BCA'),
  ];

  /// Template balasan simulasi dari dokter.
  /// Bersifat perkenalan dan ramah, tanpa diagnosis atau rekomendasi obat.
  /// TODO(chat-realtime): Hapus dan ganti dengan sistem chat real-time.
  static const List<String> simulatedDoctorReplies = [
    'Halo! Terima kasih sudah menghubungi, pesan Anda sudah kami terima. Dokter akan segera menindaklanjuti setelah mengonfirmasi jadwal konsultasi ini.',
    'Selamat datang di layanan konsultasi dokter LAMON. Pesan Anda telah kami terima dan dokter akan segera bergabung sesuai jadwal konsultasi.',
    'Terima kasih telah menyampaikan keluhan Anda. Dokter kami akan segera menindaklanjuti pesan Anda dalam sesi konsultasi ini.',
  ];
}

/// Data untuk satu metode pembayaran.
class PaymentMethodData {
  final String id;
  final String name;
  final String iconLabel;

  const PaymentMethodData({
    required this.id,
    required this.name,
    required this.iconLabel,
  });
}
