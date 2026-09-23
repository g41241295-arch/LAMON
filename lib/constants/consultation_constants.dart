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
  /// TODO(chat-realtime): Hapus dan ganti dengan sistem chat real-time.
  static const List<String> simulatedDoctorReplies = [
    'Dari keluhan yang telah dijelaskan, hal tersebut termasuk salah satu gejala dari penyakit GERD. Kapan terakhir kali anda makan?',
    'Baik, saya mengerti. Apakah Anda sering merasakan nyeri ulu hati atau sensasi terbakar di dada?',
    'Terima kasih sudah menceritakan keluhannya. Saya akan bantu analisis lebih lanjut. Apakah ada riwayat penyakit lambung sebelumnya?',
    'Sebaiknya hindari makanan pedas dan asam untuk sementara. Makan dengan porsi kecil tapi sering. Apakah ada pertanyaan lain?',
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
