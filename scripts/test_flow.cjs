const auth = require('C:/Users/ASUS/AppData/Roaming/npm/node_modules/firebase-tools/lib/auth');
const https = require('https');

async function main() {
  const ac = auth.getGlobalDefaultAccount();
  const token = (await auth.getAccessToken(ac.tokens.refresh_token, [])).access_token;
  const projectId = 'lamon-a720b';

  // Helper for REST
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

  // Create test consultation 1
  const patientUid = '9HmOwnDZ5VYIUflgYGXRg9bHRvt2'; // C_14_Dhieta Ayu Larasati
  const docId = 'test_booking_' + Date.now();
  console.log('Creating test consultation:', docId);

  const createRes = await request('PATCH', `users/${patientUid}/consultations/${docId}`, {
    fields: {
      doctorId: { stringValue: 'dr_ketut_maulana' },
      doctorName: { stringValue: 'Dr. Ketut Maulana' },
      doctorSpecialty: { stringValue: 'Dokter Umum' },
      scheduledTime: { stringValue: '08.00 - 11.00' },
      sessionFee: { integerValue: '50000' },
      serviceFee: { integerValue: '10000' },
      totalFee: { integerValue: '60000' },
      paymentMethod: { stringValue: 'mandiri' },
      paymentMethodName: { stringValue: 'Bank Mandiri' },
      virtualAccountNumber: { stringValue: '88099 20261022001' },
      orderId: { stringValue: 'LAMON-' + Date.now() },
      paymentStatus: { stringValue: 'paid' },
      status: { stringValue: 'waiting' },
      createdAt: { timestampValue: new Date().toISOString() },
      paymentDeadline: { timestampValue: new Date(Date.now() + 86400000).toISOString() },
      patientUid: { stringValue: patientUid },
      patientName: { stringValue: 'C_14_Dhieta Ayu Larasati' },
      patientGender: { stringValue: 'Wanita' },
      patientAge: { integerValue: '21' },
      unreadForDoctor: { integerValue: '0' },
      unreadForPatient: { integerValue: '0' }
    }
  });

  console.log('Create result:', createRes.status);

  // Read back
  const readRes = await request('GET', `users/${patientUid}/consultations/${docId}`);
  console.log('Read back status:', readRes.data.fields.status?.stringValue, 'paymentStatus:', readRes.data.fields.paymentStatus?.stringValue);

  // Now simulate confirmConsultation
  console.log('\nSimulating confirmConsultation...');
  const confirmRes = await request('PATCH', `users/${patientUid}/consultations/${docId}?updateMask.fieldPaths=status&updateMask.fieldPaths=doctorConfirmedAt&updateMask.fieldPaths=unreadForDoctor&updateMask.fieldPaths=lastReadByDoctorAt`, {
    fields: {
      status: { stringValue: 'active' },
      doctorConfirmedAt: { timestampValue: new Date().toISOString() },
      unreadForDoctor: { integerValue: '0' },
      lastReadByDoctorAt: { timestampValue: new Date().toISOString() }
    }
  });
  console.log('Confirm result:', confirmRes.status);
  const readAfterConfirm = await request('GET', `users/${patientUid}/consultations/${docId}`);
  console.log('After confirm: status =', readAfterConfirm.data.fields.status?.stringValue, 'doctorConfirmedAt =', readAfterConfirm.data.fields.doctorConfirmedAt?.timestampValue);

  // Now simulate doctor sends "halo"
  console.log('\nSimulating doctor sendMessage("halo")...');
  const msgId = 'msg_' + Date.now();
  await request('PATCH', `users/${patientUid}/consultations/${docId}/messages/${msgId}`, {
    fields: {
      senderType: { stringValue: 'doctor' },
      text: { stringValue: 'halo' },
      sentAt: { timestampValue: new Date().toISOString() },
      type: { stringValue: 'text' }
    }
  });
  const updateSummaryRes = await request('PATCH', `users/${patientUid}/consultations/${docId}?updateMask.fieldPaths=lastMessageText&updateMask.fieldPaths=lastMessageAt&updateMask.fieldPaths=lastMessageSenderType&updateMask.fieldPaths=unreadForPatient`, {
    fields: {
      lastMessageText: { stringValue: 'halo' },
      lastMessageAt: { timestampValue: new Date().toISOString() },
      lastMessageSenderType: { stringValue: 'doctor' },
      unreadForPatient: { integerValue: '1' }
    }
  });
  console.log('Update summary result:', updateSummaryRes.status);

  const readFinal = await request('GET', `users/${patientUid}/consultations/${docId}`);
  console.log('\n=== FINAL DOC STATE ===');
  console.log('status:', readFinal.data.fields.status?.stringValue);
  console.log('doctorConfirmedAt:', readFinal.data.fields.doctorConfirmedAt?.timestampValue);
  console.log('lastMessageText:', readFinal.data.fields.lastMessageText?.stringValue);
  console.log('lastMessageSenderType:', readFinal.data.fields.lastMessageSenderType?.stringValue);
  console.log('lastMessageAt:', readFinal.data.fields.lastMessageAt?.timestampValue);
  console.log('unreadForDoctor:', readFinal.data.fields.unreadForDoctor?.integerValue);
  console.log('unreadForPatient:', readFinal.data.fields.unreadForPatient?.integerValue);

  // Clean up test document
  await request('DELETE', `users/${patientUid}/consultations/${docId}`);
  console.log('Cleaned up test document.');
}

main().catch(console.error);
