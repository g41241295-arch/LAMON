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
///   doctorName: String,
///   doctorSpecialty: String,
///   scheduledTime: String,
///   sessionFee: Number,
///   serviceFee: Number,
///   totalFee: Number,
///   paymentMethod: String,
///   paymentMethodName: String,
///   virtualAccountNumber: String,
///   orderId: String,
///   paymentStatus: String,
///   paymentDeadline: Timestamp,
///   createdAt: Timestamp,
///   // Field Hak Akses Dokter:
///   patientUid: String,
///   patientName: String,
///   patientGender: String?,
///   patientAge: Number?,
///   status: String,              // "waiting" (paid, belum dikonfirmasi) | "active"
///   doctorConfirmedAt: Timestamp?,
///   lastMessageText: String?,
///   lastMessageAt: Timestamp?,
///   lastMessageSenderType: String?, // "patient" | "doctor"
///   unreadForDoctor: Number,
///   unreadForPatient: Number,
///   lastReadByDoctorAt: Timestamp?,
///   lastReadByPatientAt: Timestamp?,
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

  // Field Hak Akses Dokter (Null-safe / backwards compatible)
  final String patientUid;
  final String patientName;
  final String? patientGender;
  final int? patientAge;
  final String status; // "waiting" | "active" (data lama tanpa status default "active")
  final DateTime? doctorConfirmedAt;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderType;
  final int unreadForDoctor;
  final int unreadForPatient;
  final DateTime? lastReadByDoctorAt;
  final DateTime? lastReadByPatientAt;

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
    this.patientUid = '',
    this.patientName = '',
    this.patientGender,
    this.patientAge,
    this.status = 'active',
    this.doctorConfirmedAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSenderType,
    this.unreadForDoctor = 0,
    this.unreadForPatient = 0,
    this.lastReadByDoctorAt,
    this.lastReadByPatientAt,
  });

  /// Konsultasi sedang menunggu konfirmasi dokter.
  bool get isWaiting => status == 'waiting';

  /// Konsultasi sudah aktif.
  bool get isActive => status == 'active';

  /// Tampilan nama pasien (dengan fallback).
  String get displayPatientName {
    if (patientName.trim().isNotEmpty) return patientName.trim();
    return 'Pasien';
  }

  /// Inisial nama pasien (maksimal 2 huruf) untuk avatar.
  String get patientInitials {
    final name = displayPatientName;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Konsultasi baru dibuat (<24 jam).
  bool get isNew {
    final diff = DateTime.now().difference(createdAt);
    return diff.inHours < 24;
  }

  /// Path asset foto dokter dari pemetaan doctorId atau nama dokter
  String get doctorPhotoAsset {
    final lowerId = doctorId.toLowerCase();
    final lowerName = doctorName.toLowerCase();
    if (lowerId.contains('ketut') || lowerName.contains('ketut')) {
      return 'assets/images/doctors/Ketut Maulana.jpg';
    }
    if (lowerId.contains('oggy') || lowerName.contains('oggy')) {
      return 'assets/images/doctors/Oggy Agustin.jpg';
    }
    if (lowerId.contains('dandi') || lowerName.contains('dandi')) {
      return 'assets/images/doctors/Dandi Wijaya.jpg';
    }
    return '';
  }

  String get doctorPhotoUrl => doctorPhotoAsset;

  ConsultationModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? scheduledTime,
    int? sessionFee,
    int? serviceFee,
    int? totalFee,
    String? paymentMethod,
    String? paymentMethodName,
    String? virtualAccountNumber,
    String? orderId,
    PaymentStatus? paymentStatus,
    DateTime? paymentDeadline,
    DateTime? createdAt,
    String? patientUid,
    String? patientName,
    String? patientGender,
    int? patientAge,
    String? status,
    DateTime? doctorConfirmedAt,
    String? lastMessageText,
    DateTime? lastMessageAt,
    String? lastMessageSenderType,
    int? unreadForDoctor,
    int? unreadForPatient,
    DateTime? lastReadByDoctorAt,
    DateTime? lastReadByPatientAt,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      sessionFee: sessionFee ?? this.sessionFee,
      serviceFee: serviceFee ?? this.serviceFee,
      totalFee: totalFee ?? this.totalFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      virtualAccountNumber: virtualAccountNumber ?? this.virtualAccountNumber,
      orderId: orderId ?? this.orderId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      createdAt: createdAt ?? this.createdAt,
      patientUid: patientUid ?? this.patientUid,
      patientName: patientName ?? this.patientName,
      patientGender: patientGender ?? this.patientGender,
      patientAge: patientAge ?? this.patientAge,
      status: status ?? this.status,
      doctorConfirmedAt: doctorConfirmedAt ?? this.doctorConfirmedAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderType: lastMessageSenderType ?? this.lastMessageSenderType,
      unreadForDoctor: unreadForDoctor ?? this.unreadForDoctor,
      unreadForPatient: unreadForPatient ?? this.unreadForPatient,
      lastReadByDoctorAt: lastReadByDoctorAt ?? this.lastReadByDoctorAt,
      lastReadByPatientAt: lastReadByPatientAt ?? this.lastReadByPatientAt,
    );
  }

  factory ConsultationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // Coba ambil patientUid dari data, atau parse dari document reference path:
    // users/{patientUid}/consultations/{docId}
    String derivedPatientUid = data['patientUid'] as String? ?? '';
    if (derivedPatientUid.isEmpty) {
      final pathSegments = doc.reference.path.split('/');
      final usersIdx = pathSegments.indexOf('users');
      if (usersIdx != -1 && usersIdx + 1 < pathSegments.length) {
        derivedPatientUid = pathSegments[usersIdx + 1];
      }
    }

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
      patientUid: derivedPatientUid,
      patientName: data['patientName'] as String? ?? '',
      patientGender: data['patientGender'] as String?,
      patientAge: (data['patientAge'] as num?)?.toInt(),
      status: data['status'] as String? ?? 'active',
      doctorConfirmedAt: (data['doctorConfirmedAt'] as Timestamp?)?.toDate(),
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderType: data['lastMessageSenderType'] as String?,
      unreadForDoctor: (data['unreadForDoctor'] as num?)?.toInt() ?? 0,
      unreadForPatient: (data['unreadForPatient'] as num?)?.toInt() ?? 0,
      lastReadByDoctorAt: (data['lastReadByDoctorAt'] as Timestamp?)?.toDate(),
      lastReadByPatientAt: (data['lastReadByPatientAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        if (id.isNotEmpty) 'consultationId': id,
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
        'paymentDeadline': Timestamp.fromDate(paymentDeadline),
        'createdAt': FieldValue.serverTimestamp(),
        'patientUid': patientUid,
        'patientName': patientName,
        if (patientGender != null) 'patientGender': patientGender,
        if (patientAge != null) 'patientAge': patientAge,
        'status': status,
        if (doctorConfirmedAt != null)
          'doctorConfirmedAt': Timestamp.fromDate(doctorConfirmedAt!),
        if (lastMessageText != null) 'lastMessageText': lastMessageText,
        if (lastMessageAt != null)
          'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
        if (lastMessageSenderType != null)
          'lastMessageSenderType': lastMessageSenderType,
        'unreadForDoctor': unreadForDoctor,
        'unreadForPatient': unreadForPatient,
        if (lastReadByDoctorAt != null)
          'lastReadByDoctorAt': Timestamp.fromDate(lastReadByDoctorAt!),
        if (lastReadByPatientAt != null)
          'lastReadByPatientAt': Timestamp.fromDate(lastReadByPatientAt!),
      };
}

/// Model untuk satu pesan di chat konsultasi.
class ChatMessage {
  final String id;
  final String senderType; // "patient" | "doctor"
  final String text;
  final DateTime sentAt;
  final String type; // "text" | "image" | "file"
  final String? attachmentUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;

  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.text,
    required this.sentAt,
    this.type = 'text',
    this.attachmentUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
  });

  bool get isDoctor => senderType == 'doctor';
  bool get isPatient => senderType == 'patient';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
  bool get isImage => type == 'image';
  bool get isFile => type == 'file';

  factory ChatMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderType: data['senderType'] as String? ?? 'doctor',
      text: data['text'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] as String? ?? 'text',
      attachmentUrl: data['attachmentUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: (data['fileSize'] as num?)?.toInt(),
      mimeType: data['mimeType'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderType': senderType,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
        'type': type,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (mimeType != null) 'mimeType': mimeType,
      };
}
