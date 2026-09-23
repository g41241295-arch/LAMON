import 'package:cloud_firestore/cloud_firestore.dart';

/// Status pembayaran konsultasi.
enum PaymentStatus {
  pending,
  paid;

  String get value => name; // "pending" / "paid"

  static PaymentStatus fromString(String? s) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Model untuk satu booking konsultasi dokter.
///
/// Struktur Firestore:
/// ```
/// users/{uid}/consultations/{consultationId} {
///   doctorId: String,
///   doctorName: String,         // snapshot nama dokter saat booking
///   doctorSpecialty: String,    // snapshot spesialisasi saat booking
///   scheduledTime: String,      // mis. "07.00 - 11.00"
///   sessionFee: Number,         // harga dokter
///   serviceFee: Number,         // biaya layanan app (konstanta)
///   totalFee: Number,           // sessionFee + serviceFee
///   paymentMethod: String,      // id metode pembayaran
///   paymentMethodName: String,  // nama metode pembayaran
///   virtualAccountNumber: String,
///   orderId: String,
///   paymentStatus: String,      // "pending" | "paid"
///   paymentDeadline: Timestamp,
///   createdAt: Timestamp,       // server timestamp
/// }
/// ```
class ConsultationModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String scheduledTime;
  final int sessionFee;
  final int serviceFee;
  final int totalFee;
  final String paymentMethod;
  final String paymentMethodName;
  final String virtualAccountNumber;
  final String orderId;
  final PaymentStatus paymentStatus;
  final DateTime paymentDeadline;
  final DateTime createdAt;

  const ConsultationModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.scheduledTime,
    required this.sessionFee,
    required this.serviceFee,
    required this.totalFee,
    required this.paymentMethod,
    required this.paymentMethodName,
    required this.virtualAccountNumber,
    required this.orderId,
    required this.paymentStatus,
    required this.paymentDeadline,
    required this.createdAt,
  });

  factory ConsultationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ConsultationModel(
      id: doc.id,
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      doctorSpecialty: data['doctorSpecialty'] as String? ?? '',
      scheduledTime: data['scheduledTime'] as String? ?? '',
      sessionFee: (data['sessionFee'] as num?)?.toInt() ?? 0,
      serviceFee: (data['serviceFee'] as num?)?.toInt() ?? 0,
      totalFee: (data['totalFee'] as num?)?.toInt() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? '',
      paymentMethodName: data['paymentMethodName'] as String? ?? '',
      virtualAccountNumber: data['virtualAccountNumber'] as String? ?? '',
      orderId: data['orderId'] as String? ?? '',
      paymentStatus: PaymentStatus.fromString(data['paymentStatus'] as String?),
      paymentDeadline: (data['paymentDeadline'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'doctorSpecialty': doctorSpecialty,
        'scheduledTime': scheduledTime,
        'sessionFee': sessionFee,
        'serviceFee': serviceFee,
        'totalFee': totalFee,
        'paymentMethod': paymentMethod,
        'paymentMethodName': paymentMethodName,
        'virtualAccountNumber': virtualAccountNumber,
        'orderId': orderId,
        'paymentStatus': paymentStatus.value,
        'paymentDeadline':
            Timestamp.fromDate(paymentDeadline),
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// Model untuk satu pesan di chat konsultasi.
///
/// Struktur Firestore:
/// ```
/// users/{uid}/consultations/{consultationId}/messages/{messageId} {
///   senderType: String,  // "patient" | "doctor"
///   text: String,
///   sentAt: Timestamp,   // server timestamp
/// }
/// ```
class ChatMessage {
  final String id;
  final String senderType; // "patient" | "doctor"
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.text,
    required this.sentAt,
  });

  bool get isPatient => senderType == 'patient';
  bool get isDoctor => senderType == 'doctor';

  factory ChatMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatMessage(
      id: doc.id,
      senderType: data['senderType'] as String? ?? 'patient',
      text: data['text'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderType': senderType,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
      };
}
