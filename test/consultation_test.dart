import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/constants/consultation_constants.dart';
import 'package:lamon/constants/practice_slot_constants.dart';
import 'package:lamon/models/consultation_model.dart';
import 'package:lamon/models/doctor_model.dart';
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
        const Duration(hours: 24),
      );
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
  });
}
