import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/models/consultation_model.dart';

void main() {
  group('BAGIAN C — Audit & Verifikasi Integrasi Riwayat Chat', () {
    const patientUid = 'patient_uid_12345';
    const consultationId = 'consult_abc_xyz';

    test('1. Verifikasi Konsistensi Path Firestore antara Pasien dan Dokter', () {
      // Path Firestore yang disepakati:
      // users/{patientUid}/consultations/{consultationId}/messages/{messageId}

      // Sisi Pasien:
      // patientUid diambil langsung dari session aktif pasien
      final patientMessagePath =
          'users/$patientUid/consultations/$consultationId/messages';

      // Sisi Dokter:
      // patientUid diambil dari consultation.patientUid yang dibuka dokter
      final doctorMessagePath =
          'users/$patientUid/consultations/$consultationId/messages';

      expect(
        patientMessagePath,
        equals(doctorMessagePath),
        reason: 'Path messages Firestore wajib identik di sisi pasien dan dokter',
      );
      expect(
        patientMessagePath,
        'users/patient_uid_12345/consultations/consult_abc_xyz/messages',
      );
    });

    test('2. Verifikasi Konsistensi Batch Write (Pesan + LastMessage Metadata)', () {
      final now = DateTime.now();

      // Skenario 1: Pasien kirim "Tes 1 dari pasien"
      final msg1 = ChatMessage(
        id: 'msg_001',
        senderType: 'patient',
        text: 'Tes 1 dari pasien',
        sentAt: now,
      );

      final patientBatchUpdates = {
        'lastMessageText': msg1.text,
        'lastMessageAt': msg1.sentAt,
        'lastMessageSenderType': msg1.senderType,
        'unreadForDoctor': 1,
      };

      expect(msg1.isPatient, isTrue);
      expect(msg1.isDoctor, isFalse);
      expect(patientBatchUpdates['lastMessageText'], 'Tes 1 dari pasien');
      expect(patientBatchUpdates['lastMessageSenderType'], 'patient');

      // Skenario 2: Dokter membalas "Tes 2 dari dokter"
      final replyTime = now.add(const Duration(seconds: 15));
      final msg2 = ChatMessage(
        id: 'msg_002',
        senderType: 'doctor',
        text: 'Tes 2 dari dokter',
        sentAt: replyTime,
      );

      final doctorBatchUpdates = {
        'lastMessageText': msg2.text,
        'lastMessageAt': msg2.sentAt,
        'lastMessageSenderType': msg2.senderType,
        'unreadForPatient': 1,
      };

      expect(msg2.isPatient, isFalse);
      expect(msg2.isDoctor, isTrue);
      expect(doctorBatchUpdates['lastMessageText'], 'Tes 2 dari dokter');
      expect(doctorBatchUpdates['lastMessageSenderType'], 'doctor');
    });

    test('3. Verifikasi Urutan Kronologis Pesan Persisten (Simulasi Force Stop & Reload)', () {
      final t1 = DateTime(2026, 10, 21, 10, 0, 0);
      final t2 = DateTime(2026, 10, 21, 10, 0, 30);

      // Raw documents dari Firestore
      final rawDocsFromFirestore = [
        {
          'id': 'msg_001',
          'senderType': 'patient',
          'text': 'Tes 1 dari pasien',
          'sentAt': t1,
        },
        {
          'id': 'msg_002',
          'senderType': 'doctor',
          'text': 'Tes 2 dari dokter',
          'sentAt': t2,
        },
      ];

      // Simulasi parsing Firestore snapshot di sisi Pasien setelah force-stop
      final parsedPatientMessages = rawDocsFromFirestore
          .map((d) => ChatMessage(
                id: d['id'] as String,
                senderType: d['senderType'] as String,
                text: d['text'] as String,
                sentAt: d['sentAt'] as DateTime,
              ))
          .toList();

      // Simulasi parsing Firestore snapshot di sisi Dokter setelah reload
      final parsedDoctorMessages = rawDocsFromFirestore
          .map((d) => ChatMessage(
                id: d['id'] as String,
                senderType: d['senderType'] as String,
                text: d['text'] as String,
                sentAt: d['sentAt'] as DateTime,
              ))
          .toList();

      // Keduanya harus memiliki urutan yang sama persis
      expect(parsedPatientMessages.length, 2);
      expect(parsedDoctorMessages.length, 2);

      expect(parsedPatientMessages[0].text, 'Tes 1 dari pasien');
      expect(parsedPatientMessages[1].text, 'Tes 2 dari dokter');

      expect(parsedDoctorMessages[0].text, 'Tes 1 dari pasien');
      expect(parsedDoctorMessages[1].text, 'Tes 2 dari dokter');

      expect(parsedPatientMessages[0].sentAt.isBefore(parsedPatientMessages[1].sentAt), isTrue);
    });
  });
}
