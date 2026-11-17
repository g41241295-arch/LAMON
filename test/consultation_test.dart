import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/constants/consultation_constants.dart';
import 'package:lamon/constants/practice_slot_constants.dart';
import 'package:lamon/models/consultation_model.dart';
import 'package:lamon/models/doctor_model.dart';
import 'package:lamon/services/consultation_service.dart';
import 'package:lamon/utils/app_date_formatter.dart';

void main() {
  group('Consultation Models & Constants Tests', () {
    test('ConsultationConstants has valid fee, methods, and replies', () {
      expect(ConsultationConstants.serviceFee, 10000);
      expect(ConsultationConstants.paymentMethods.length, 5);
      expect(ConsultationConstants.simulatedDoctorReplies.isNotEmpty, true);
      expect(ConsultationConstants.vaPrefix, '88099');
      expect(
        ConsultationConstants.paymentDeadlineDuration,
        ConsultationConstants.kPaymentWindow,
      );
      expect(ConsultationConstants.kMaxAttachmentBytes, 700000);
      expect(ConsultationConstants.kShowAutoReplyLabel, true);
    });

    test('DoctorModel and OperatingHour serialization', () {
      const opHour = OperatingHour(start: '07.00', end: '11.00');
      expect(opHour.display, '07.00 - 11.00');
      final hourMap = opHour.toMap();
      expect(hourMap['start'], '07.00');
      expect(hourMap['end'], '11.00');

      final fromMapHour = OperatingHour.fromMap(hourMap);
      expect(fromMapHour.start, '07.00');
      expect(fromMapHour.end, '11.00');

      const doctor = DoctorModel(
        id: 'doc_1',
        name: 'dr. Andi Pratama, Sp.PD',
        specialty: 'Spesialis Penyakit Dalam',
        experienceYears: 8,
        photoUrl: '',
        price: 50000,
        operatingHours: [opHour],
        alumni: 'Universitas Indonesia',
        practiceLocation: 'RS Sehat Sentosa',
        strNumber: 'STR-1234567890',
        isRecommended: true,
        gender: 'Laki-laki',
      );

      expect(doctor.id, 'doc_1');
      expect(doctor.name, 'dr. Andi Pratama, Sp.PD');
      expect(doctor.specialtyDisplay, 'Spesialis Penyakit Dalam • 8 tahun');
      expect(doctor.primaryHour?.display, '07.00 - 11.00');
      expect(doctor.formattedNameWithDoctorTitle, 'dr. Andi Pratama, Sp.PD');

      // Test dokter tanpa prefiks "dr."
      const doctorNoPrefix = DoctorModel(
        id: 'doc_2',
        name: 'Budi Santoso',
        specialty: 'Dokter Umum',
        experienceYears: 5,
        photoUrl: '',
        price: 35000,
        operatingHours: [],
        alumni: 'Universitas Airlangga',
        practiceLocation: 'Klinik Sehat',
        strNumber: 'STR-999',
        isRecommended: false,
      );
      expect(doctorNoPrefix.formattedNameWithDoctorTitle, 'dr. Budi Santoso');

      final firestoreMap = doctor.toFirestore();
      expect(firestoreMap['name'], doctor.name);
      expect(firestoreMap['price'], 50000);
      expect(firestoreMap['isRecommended'], true);
      expect(firestoreMap['gender'], 'Laki-laki');
      expect(
        (firestoreMap['operatingHours'] as List).first['start'],
        '07.00',
      );
    });

    test('ConsultationModel and PaymentStatus enum', () {
      expect(PaymentStatus.fromString('pending'), PaymentStatus.pending);
      expect(PaymentStatus.fromString('paid'), PaymentStatus.paid);
      expect(PaymentStatus.fromString('unknown'), PaymentStatus.pending);

      final now = DateTime.now();
      final deadline = now.add(const Duration(hours: 24));

      final consultation = ConsultationModel(
        id: 'consult_1',
        doctorId: 'doc_1',
        doctorName: 'dr. Andi Pratama, Sp.PD',
        doctorSpecialty: 'Spesialis Penyakit Dalam',
        scheduledTime: '07.00 - 11.00',
        sessionFee: 50000,
        serviceFee: 10000,
        totalFee: 60000,
        paymentMethod: 'bca',
        paymentMethodName: 'BCA',
        virtualAccountNumber: '88099123456789',
        orderId: 'ORD-123456',
        paymentStatus: PaymentStatus.pending,
        paymentDeadline: deadline,
        createdAt: now,
        patientUid: 'user_123',
        patientName: 'Ahmad Dahlan',
        patientGender: 'Laki-laki',
        patientAge: 28,
        status: 'waiting',
      );

      expect(consultation.isWaiting, true);
      expect(consultation.isActive, false);
      expect(consultation.displayPatientName, 'Ahmad Dahlan');
      expect(consultation.patientInitials, 'AD');

      final firestoreMap = consultation.toFirestore();
      expect(firestoreMap['doctorId'], 'doc_1');
      expect(firestoreMap['totalFee'], 60000);
      expect(firestoreMap['paymentStatus'], 'pending');
      expect(firestoreMap['paymentMethod'], 'bca');
      expect(firestoreMap['patientUid'], 'user_123');
      expect(firestoreMap['patientName'], 'Ahmad Dahlan');
      expect(firestoreMap['status'], 'waiting');
    });

    test('ChatMessage properties', () {
      final now = DateTime.now();
      final patientMsg = ChatMessage(
        id: 'msg_1',
        senderType: 'patient',
        text: 'Halo dok, saya sering sakit perut setelah makan.',
        sentAt: now,
      );

      expect(patientMsg.isPatient, true);
      expect(patientMsg.isDoctor, false);

      final docMsg = ChatMessage(
        id: 'msg_2',
        senderType: 'doctor',
        text: 'Halo, apakah rasa sakitnya seperti terbakar?',
        sentAt: now,
      );

      expect(docMsg.isPatient, false);
      expect(docMsg.isDoctor, true);

      final firestoreMap = patientMsg.toFirestore();
      expect(firestoreMap['senderType'], 'patient');
      expect(
        firestoreMap['text'],
        'Halo dok, saya sering sakit perut setelah makan.',
      );
    });

    test('PracticeSlotConstants definitions', () {
      expect(PracticeSlotConstants.allSlots.length, 3);
      expect(PracticeSlotConstants.pagi.id, 'pagi');
      expect(PracticeSlotConstants.siang.id, 'siang');
      expect(PracticeSlotConstants.malam.id, 'malam');
      expect(PracticeSlotConstants.findById('pagi')?.label, 'Pagi');
      expect(PracticeSlotConstants.findById('siang')?.label, 'Siang');
      expect(PracticeSlotConstants.findById('malam')?.label, 'Malam');
      expect(PracticeSlotConstants.findById('invalid'), null);
    });

    test('AppDateFormatter Indonesian formats and greeting', () {
      final date = DateTime(2026, 9, 28);
      expect(AppDateFormatter.formatDateKey(date), '2026-09-28');
      expect(AppDateFormatter.formatMonthYear(date), 'September 2026');
      expect(AppDateFormatter.formatLongDate(date).contains('September 2026'), true);

      final morning = DateTime(2026, 9, 28, 8, 0);
      final afternoon = DateTime(2026, 9, 28, 13, 0);
      final evening = DateTime(2026, 9, 28, 16, 0);
      final night = DateTime(2026, 9, 28, 20, 0);

      expect(AppDateFormatter.getGreetingWord(morning), 'Selamat pagi,');
      expect(AppDateFormatter.getGreetingWord(afternoon), 'Selamat siang,');
      expect(AppDateFormatter.getGreetingWord(evening), 'Selamat sore,');
      expect(AppDateFormatter.getGreetingWord(night), 'Selamat malam,');
    });

    test('Revisi 12: generateDoctorAutoReplyText generates correct greeting and name/specialty formatting', () {
      // 1. Dr. Oggy Agustin (Dokter Umum) di pagi hari (09.00)
      final oggyMorning = ConsultationService.generateDoctorAutoReplyText(
        doctorName: 'Dr. Oggy Agustin',
        doctorSpecialty: 'Dokter Umum',
        now: DateTime(2026, 11, 15, 9, 0),
      );
      expect(
        oggyMorning,
        'Halo selamat pagi. Perkenalkan saya dokter umum Oggy. Apa keluhan yang anda alami?',
      );
      expect(oggyMorning.contains('Perkenalkan saya dokter umum Oggy.'), true);

      // 2. Dr. Ketut Maulana (Dokter Umum) di siang hari (12.30)
      final ketutSiang = ConsultationService.generateDoctorAutoReplyText(
        doctorName: 'Dr. Ketut Maulana',
        doctorSpecialty: 'Dokter Umum',
        now: DateTime(2026, 11, 15, 12, 30),
      );
      expect(
        ketutSiang,
        'Halo selamat siang. Perkenalkan saya dokter umum Ketut. Apa keluhan yang anda alami?',
      );

      // 3. Dr. Dandi Wijaya (Spesialis Penyakit Dalam) di sore hari (16.00)
      final dandiSore = ConsultationService.generateDoctorAutoReplyText(
        doctorName: 'Dr. Dandi Wijaya',
        doctorSpecialty: 'Spesialis Penyakit Dalam',
        now: DateTime(2026, 11, 15, 16, 0),
      );
      expect(
        dandiSore,
        'Halo selamat sore. Perkenalkan saya dokter spesialis penyakit dalam Dandi. Apa keluhan yang anda alami?',
      );

      // 4. Dokter Spesialis dengan gelar belakang dan jam malam (20.00)
      final rinaMalam = ConsultationService.generateDoctorAutoReplyText(
        doctorName: 'dr. Rina Suryani, Sp.A',
        doctorSpecialty: 'Spesialis Anak',
        now: DateTime(2026, 11, 15, 20, 0),
      );
      expect(
        rinaMalam,
        'Halo selamat malam. Perkenalkan saya dokter spesialis anak Rina. Apa keluhan yang anda alami?',
      );

      // 5. Fallback tanpa spesialisasi
      final fallbackReply = ConsultationService.generateDoctorAutoReplyText(
        doctorName: 'drg. Maya',
        doctorSpecialty: '',
        now: DateTime(2026, 11, 15, 8, 0),
      );
      expect(
        fallbackReply,
        'Halo selamat pagi. Perkenalkan saya dokter Maya. Apa keluhan yang anda alami?',
      );

      // 6. Bebas dari nama obat, diagnosis, atau penyakit
      final textLower = oggyMorning.toLowerCase();
      expect(textLower.contains('obat'), false);
      expect(textLower.contains('maag'), false);
      expect(textLower.contains('gerd'), false);
      expect(textLower.contains('antasida'), false);
    });

    test('Revisi 12: ChatMessage and ConsultationModel fields serialization', () {
      final msg = ChatMessage(
        id: 'msg_123',
        senderType: 'doctor',
        text: 'Halo selamat pagi. Perkenalkan saya dokter umum Oggy. Apa keluhan yang anda alami?',
        sentAt: DateTime(2026, 11, 15, 9, 0),
        type: 'file',
        attachmentId: 'att_123_456',
        fileName: 'hasil_lab.pdf',
        sizeBytes: 250000,
        mimeType: 'application/pdf',
        isAutoReply: true,
      );

      expect(msg.isAutoReply, true);
      expect(msg.isFile, true);
      expect(msg.hasAttachment, true);
      expect(msg.attachmentId, 'att_123_456');
      expect(msg.effectiveFileSize, 250000);

      final map = msg.toFirestore();
      expect(map['isAutoReply'], true);
      expect(map['attachmentId'], 'att_123_456');
      expect(map['sizeBytes'], 250000);
      expect(map['fileName'], 'hasil_lab.pdf');
    });
  });
}
