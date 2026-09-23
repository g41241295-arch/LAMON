import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/constants/consultation_constants.dart';
import 'package:lamon/models/consultation_model.dart';
import 'package:lamon/models/doctor_model.dart';

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
      );

      expect(doctor.id, 'doc_1');
      expect(doctor.name, 'dr. Andi Pratama, Sp.PD');
      expect(doctor.specialtyDisplay, 'Spesialis Penyakit Dalam • 8 tahun');
      expect(doctor.primaryHour?.display, '07.00 - 11.00');

      final firestoreMap = doctor.toFirestore();
      expect(firestoreMap['name'], doctor.name);
      expect(firestoreMap['price'], 50000);
      expect(firestoreMap['isRecommended'], true);
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
      );

      final firestoreMap = consultation.toFirestore();
      expect(firestoreMap['doctorId'], 'doc_1');
      expect(firestoreMap['totalFee'], 60000);
      expect(firestoreMap['paymentStatus'], 'pending');
      expect(firestoreMap['paymentMethod'], 'bca');
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
  });
}
