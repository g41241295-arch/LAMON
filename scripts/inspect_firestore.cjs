const { getGlobalDefaultAccount } = require('C:/Users/ASUS/AppData/Roaming/npm/node_modules/firebase-tools/lib/auth');
const https = require('https');

async function main() {
  const auth = require('C:/Users/ASUS/AppData/Roaming/npm/node_modules/firebase-tools/lib/auth');
  const ac = auth.getGlobalDefaultAccount();
  if (!ac || !ac.tokens || !ac.tokens.refresh_token) {
    throw new Error('No valid Firebase CLI account token found.');
  }
  const tokenObj = await auth.getAccessToken(ac.tokens.refresh_token, []);
  const token = tokenObj.access_token;
  const projectId = 'lamon-a720b';

  console.log('Firebase user logged in CLI:', ac.user?.email);

  // Helper for GET
  function getJson(path) {
    return new Promise((resolve, reject) => {
      const url = new URL(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${path}`);
      https.get(url, { headers: { 'Authorization': `Bearer ${token}` } }, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(body));
          } catch (e) {
            resolve(body);
          }
        });
      }).on('error', reject);
    });
  }

  // Helper for POST (runQuery)
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
      }, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(body));
          } catch (e) {
            resolve(body);
          }
        });
      });
      req.on('error', reject);
      req.write(data);
      req.end();
    });
  }

  // Find all consultations for dr_ketut_maulana
  console.log('\n--- Consultations for dr_ketut_maulana: ---');
  const ketutConsults = await runQuery({
    from: [{ collectionId: 'consultations', allDescendants: true }],
    where: {
      fieldFilter: {
        field: { fieldPath: 'doctorId' },
        op: 'EQUAL',
        value: { stringValue: 'dr_ketut_maulana' }
      }
    }
  });

  ketutConsults.forEach((r, idx) => {
    if (r.document) {
      const f = r.document.fields;
      console.log(`\n[${idx + 1}] Path: ${r.document.name}`);
      console.log(`    Status: ${f.status?.stringValue}, PaymentStatus: ${f.paymentStatus?.stringValue}`);
      console.log(`    PatientName: ${f.patientName?.stringValue}, PatientUid: ${f.patientUid?.stringValue}`);
      console.log(`    DoctorConfirmedAt: ${f.doctorConfirmedAt?.timestampValue}`);
      console.log(`    LastMessageSenderType: ${f.lastMessageSenderType?.stringValue}`);
      console.log(`    LastMessageText: ${f.lastMessageText?.stringValue}`);
      console.log(`    LastMessageAt: ${f.lastMessageAt?.timestampValue}`);
      console.log(`    UnreadForDoctor: ${f.unreadForDoctor?.integerValue}`);
      console.log(`    UnreadForPatient: ${f.unreadForPatient?.integerValue}`);
    }
  });

  // Find user C_14_Dhieta Ayu Larasati
  console.log('\n--- Finding patient Dhieta: ---');
  const dhietaUsers = await runQuery({
    from: [{ collectionId: 'users' }],
    where: {
      fieldFilter: {
        field: { fieldPath: 'nama' },
        op: 'GREATER_THAN_OR_EQUAL',
        value: { stringValue: 'C_14' }
      }
    }
  });
  dhietaUsers.forEach(u => {
    if (u.document) {
      console.log('User:', u.document.name, JSON.stringify(u.document.fields.nama || u.document.fields.name));
    }
  });
}

main().catch(console.error);
