const auth = require('C:/Users/ASUS/AppData/Roaming/npm/node_modules/firebase-tools/lib/auth');
const https = require('https');

async function main() {
  const ac = auth.getGlobalDefaultAccount();
  const token = (await auth.getAccessToken(ac.tokens.refresh_token, [])).access_token;
  const projectId = 'lamon-a720b';

  function request(method, path, body) {
    return new Promise((resolve, reject) => {
      const url = new URL(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${path}`);
      const data = body ? JSON.stringify(body) : null;
      const req = https.request(url, {
        method,
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
        }
      }, res => {
        let b = '';
        res.on('data', c => b += c);
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, data: JSON.parse(b) });
          } catch(e) {
            resolve({ status: res.statusCode, data: b });
          }
        });
      });
      req.on('error', reject);
      if (data) req.write(data);
      req.end();
    });
  }

  function runQuery(structuredQuery) {
    return new Promise((resolve, reject) => {
      const url = new URL(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery`);
      const data = JSON.stringify({ structuredQuery });
      const req = https.request(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data)
        }
      }, res => {
        let b = '';
        res.on('data', c => b += c);
        res.on('end', () => {
          try {
            resolve(JSON.parse(b));
          } catch (e) {
            resolve(b);
          }
        });
      });
      req.on('error', reject);
      req.write(data);
      req.end();
    });
  }

  console.log('================================================================');
  console.log('TEST SUITE: UJI COBA WAJIB REVISI 4 DENGAN DATA FIRESTORE REAL');
  console.log('================================================================');

  // Function to run full test cycle for a patient
  async function testPatientCycle(patientIndex, patientUid, patientName) {
    console.log(`\n>>> [PASIEN ${patientIndex}] ${patientName} (UID: ${patientUid})`);
    const docId = `konsultasi_uji_${patientIndex}_${Date.now()}`;
    const orderId = `LAMON-TEST-${patientIndex}-${Date.now()}`;

    // 1. Pasien Baru Booking & Bayar
    console.log(`\n--- Langkah 1: Pasien ${patientName} membuat booking (status: waiting, paymentStatus: paid) ---`);
    await request('PATCH', `users/${patientUid}/consultations/${docId}`, {
      fields: {
        consultationId: { stringValue: docId },
        doctorId: { stringValue: 'dr_ketut_maulana' },
        doctorName: { stringValue: 'Dr. Ketut Maulana' },
        doctorSpecialty: { stringValue: 'Dokter Umum' },
        scheduledTime: { stringValue: '08.00 - 11.00 WIB' },
        sessionFee: { integerValue: '50000' },
        serviceFee: { integerValue: '10000' },
        totalFee: { integerValue: '60000' },
        paymentMethod: { stringValue: 'mandiri' },
        paymentMethodName: { stringValue: 'Bank Mandiri' },
        virtualAccountNumber: { stringValue: '88099 2026102299' + patientIndex },
        orderId: { stringValue: orderId },
        paymentStatus: { stringValue: 'paid' },
        status: { stringValue: 'waiting' },
        createdAt: { timestampValue: new Date().toISOString() },
        paymentDeadline: { timestampValue: new Date(Date.now() + 86400000).toISOString() },
        patientUid: { stringValue: patientUid },
        patientName: { stringValue: patientName },
        unreadForDoctor: { integerValue: '0' },
        unreadForPatient: { integerValue: '0' }
      }
    });

    // Verifikasi Dokumen Segera Setelah Booking (SEBELUM Konfirmasi)
    let docSnap = await request('GET', `users/${patientUid}/consultations/${docId}`);
    let f = docSnap.data.fields;
    console.log('Dokumen Firestore SEBELUM Konfirmasi:');
    console.log('  - Document ID           :', docId);
    console.log('  - status                :', f.status?.stringValue);
    console.log('  - paymentStatus         :', f.paymentStatus?.stringValue);
    console.log('  - doctorConfirmedAt     :', f.doctorConfirmedAt?.timestampValue ?? '(null/belum ada)');
    console.log('  - lastMessageSenderType :', f.lastMessageSenderType?.stringValue ?? '(null/belum ada)');
    console.log('  - lastMessageText       :', f.lastMessageText?.stringValue ?? '(null/belum ada)');

    // Query CollectionGroup: Verifikasi apakah masuk ke waitingConfirmationList dokter
    let doctorConsults = await runQuery({
      from: [{ collectionId: 'consultations', allDescendants: true }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'doctorId' },
          op: 'EQUAL',
          value: { stringValue: 'dr_ketut_maulana' }
        }
      }
    });
    let waitingList = doctorConsults.filter(x => x.document && x.document.fields.paymentStatus?.stringValue === 'paid' && x.document.fields.status?.stringValue === 'waiting');
    let belumDibalasList = doctorConsults.filter(x => x.document && x.document.fields.paymentStatus?.stringValue === 'paid' && x.document.fields.lastMessageSenderType?.stringValue !== 'doctor');
    let sudahDibalasList = doctorConsults.filter(x => x.document && x.document.fields.paymentStatus?.stringValue === 'paid' && x.document.fields.lastMessageSenderType?.stringValue === 'doctor');
    console.log(`  -> Beranda Badge "Menunggu Konfirmasi" : ${waitingList.length}`);
    console.log(`  -> Pesan Tab "Belum Dibalas" Count     : ${belumDibalasList.length}`);
    console.log(`  -> Pesan Tab "Sudah Dibalas" Count     : ${sudahDibalasList.length}`);

    // 2. Dokter Tekan "Konfirmasi & Mulai Chat"
    console.log(`\n--- Langkah 2: Dokter menekan "Konfirmasi & Mulai Chat" ---`);
    const confirmTime = new Date().toISOString();
    await request('PATCH', `users/${patientUid}/consultations/${docId}?updateMask.fieldPaths=status&updateMask.fieldPaths=doctorConfirmedAt&updateMask.fieldPaths=unreadForDoctor&updateMask.fieldPaths=lastReadByDoctorAt`, {
      fields: {
        status: { stringValue: 'active' },
        doctorConfirmedAt: { timestampValue: confirmTime },
        unreadForDoctor: { integerValue: '0' },
        lastReadByDoctorAt: { timestampValue: confirmTime }
      }
    });

    // Verifikasi Dokumen SESUDAH Konfirmasi
    docSnap = await request('GET', `users/${patientUid}/consultations/${docId}`);
    f = docSnap.data.fields;
    console.log('Dokumen Firestore SESUDAH Konfirmasi:');
    console.log('  - status                :', f.status?.stringValue);
    console.log('  - doctorConfirmedAt     :', f.doctorConfirmedAt?.timestampValue);
    console.log('  - unreadForDoctor       :', f.unreadForDoctor?.integerValue);

    // 3. Verifikasi Realtime Query setelah konfirmasi
    console.log(`\n--- Langkah 3: Evaluasi Realtime State Beranda setelah Konfirmasi ---`);
    doctorConsults = await runQuery({
      from: [{ collectionId: 'consultations', allDescendants: true }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'doctorId' },
          op: 'EQUAL',
          value: { stringValue: 'dr_ketut_maulana' }
        }
      }
    });
    waitingList = doctorConsults.filter(x => x.document && x.document.fields.paymentStatus?.stringValue === 'paid' && x.document.fields.status?.stringValue === 'waiting');
    console.log(`  -> Beranda Badge "Menunggu Konfirmasi" : ${waitingList.length} (Item baru otomatis keluar dari daftar menunggu)`);

    // 4. Dokter Kirim Pesan "halo" dari Layar Chat
    console.log(`\n--- Langkah 4: Dokter mengirim pesan "halo" dari ChatDokterScreen ---`);
    const msgId = `msg_${Date.now()}`;
    const msgTime = new Date().toISOString();
    await request('PATCH', `users/${patientUid}/consultations/${docId}/messages/${msgId}`, {
      fields: {
        senderType: { stringValue: 'doctor' },
        text: { stringValue: 'halo' },
        sentAt: { timestampValue: msgTime },
        type: { stringValue: 'text' }
      }
    });
    await request('PATCH', `users/${patientUid}/consultations/${docId}?updateMask.fieldPaths=lastMessageText&updateMask.fieldPaths=lastMessageAt&updateMask.fieldPaths=lastMessageSenderType&updateMask.fieldPaths=unreadForPatient`, {
      fields: {
        lastMessageText: { stringValue: 'halo' },
        lastMessageAt: { timestampValue: msgTime },
        lastMessageSenderType: { stringValue: 'doctor' },
        unreadForPatient: { integerValue: '1' }
      }
    });

    // Verifikasi Dokumen SESUDAH Dokter Kirim Pesan
    docSnap = await request('GET', `users/${patientUid}/consultations/${docId}`);
    f = docSnap.data.fields;
    console.log('Dokumen Firestore SESUDAH Dokter Mengirim "halo":');
    console.log('  - status                :', f.status?.stringValue);
    console.log('  - doctorConfirmedAt     :', f.doctorConfirmedAt?.timestampValue);
    console.log('  - lastMessageSenderType :', f.lastMessageSenderType?.stringValue);
    console.log('  - lastMessageText       :', f.lastMessageText?.stringValue);
    console.log('  - lastMessageAt         :', f.lastMessageAt?.timestampValue);
    console.log('  - unreadForPatient      :', f.unreadForPatient?.integerValue);

    // 5. Verifikasi Perpindahan Tab Pesan
    console.log(`\n--- Langkah 5: Evaluasi Realtime State Tab Pesan ---`);
    doctorConsults = await runQuery({
      from: [{ collectionId: 'consultations', allDescendants: true }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'doctorId' },
          op: 'EQUAL',
          value: { stringValue: 'dr_ketut_maulana' }
        }
      }
    });
    belumDibalasList = doctorConsults.filter(x => x.document && x.document.fields.paymentStatus?.stringValue === 'paid' && x.document.fields.lastMessageSenderType?.stringValue !== 'doctor');
    sudahDibalasList = doctorConsults.filter(x => x.document && x.document.fields.paymentStatus?.stringValue === 'paid' && x.document.fields.lastMessageSenderType?.stringValue === 'doctor');
    console.log(`  -> Pesan Tab "Belum Dibalas" Count     : ${belumDibalasList.length}`);
    console.log(`  -> Pesan Tab "Sudah Dibalas" Count     : ${sudahDibalasList.length} (Percakapan berhasil pindah ke Sudah Dibalas)`);

    return { docId, patientUid, patientName, finalDoc: f };
  }

  // Uji Pasien 1: C_14_Dhieta Ayu Larasati (UID: 9HmOwnDZ5VYIUflgYGXRg9bHRvt2)
  const result1 = await testPatientCycle(1, '9HmOwnDZ5VYIUflgYGXRg9bHRvt2', 'C_14_Dhieta Ayu Larasati');

  // Uji Pasien 2: Dhietaayuu (UID: Erj04UuDPsXBGTqCJtLiXl3qMV02)
  const result2 = await testPatientCycle(2, 'Erj04UuDPsXBGTqCJtLiXl3qMV02', 'Dhietaayuu');

  console.log('\n================================================================');
  console.log('RINGKASAN HASIL SELURUH PENGUJIAN:');
  console.log('================================================================');
  console.log('Pasien 1 (C_14_Dhieta Ayu Larasati):');
  console.log('  - ID Dokumen          :', result1.docId);
  console.log('  - Status Akhir        :', result1.finalDoc.status.stringValue);
  console.log('  - DoctorConfirmedAt   :', result1.finalDoc.doctorConfirmedAt.timestampValue);
  console.log('  - LastSenderType      :', result1.finalDoc.lastMessageSenderType.stringValue);
  console.log('  - LastMessageText     :', result1.finalDoc.lastMessageText.stringValue);

  console.log('\nPasien 2 (Dhietaayuu):');
  console.log('  - ID Dokumen          :', result2.docId);
  console.log('  - Status Akhir        :', result2.finalDoc.status.stringValue);
  console.log('  - DoctorConfirmedAt   :', result2.finalDoc.doctorConfirmedAt.timestampValue);
  console.log('  - LastSenderType      :', result2.finalDoc.lastMessageSenderType.stringValue);
  console.log('  - LastMessageText     :', result2.finalDoc.lastMessageText.stringValue);
  console.log('================================================================');
}

main().catch(console.error);
