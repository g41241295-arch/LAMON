const { getGlobalDefaultAccount } = require('C:/Users/ASUS/AppData/Roaming/npm/node_modules/firebase-tools/lib/auth');
const https = require('https');

async function main() {
  const ac = getGlobalDefaultAccount();
  if (!ac || !ac.tokens || !ac.tokens.access_token) {
    throw new Error('No valid Firebase CLI account token found.');
  }
  const token = ac.tokens.access_token;
  const projectId = 'lamon-a720b';

  const doctors = [
    {
      id: 'dr_ketut_maulana',
      fields: {
        name: { stringValue: 'Dr. Ketut Maulana' },
        specialty: { stringValue: 'Dokter Umum' },
        experienceYears: { integerValue: '8' },
        photoUrl: { stringValue: '' },
        price: { integerValue: '50000' },
        operatingHours: {
          arrayValue: {
            values: [
              { mapValue: { fields: { start: { stringValue: '07.00' }, end: { stringValue: '11.00' } } } },
              { mapValue: { fields: { start: { stringValue: '14.00' }, end: { stringValue: '17.00' } } } }
            ]
          }
        },
        alumni: { stringValue: 'Universitas Udayana' },
        practiceLocation: { stringValue: 'RS Sanglah Denpasar' },
        strNumber: { stringValue: '3217/A/KKI/2018' },
        isRecommended: { booleanValue: true }
      }
    },
    {
      id: 'dr_oggy_agustin',
      fields: {
        name: { stringValue: 'Dr. Oggy Agustin' },
        specialty: { stringValue: 'Spesialis Penyakit Dalam' },
        experienceYears: { integerValue: '12' },
        photoUrl: { stringValue: '' },
        price: { integerValue: '75000' },
        operatingHours: {
          arrayValue: {
            values: [
              { mapValue: { fields: { start: { stringValue: '08.00' }, end: { stringValue: '12.00' } } } },
              { mapValue: { fields: { start: { stringValue: '15.00' }, end: { stringValue: '18.00' } } } }
            ]
          }
        },
        alumni: { stringValue: 'Universitas Indonesia' },
        practiceLocation: { stringValue: 'RS Cipto Mangunkusumo' },
        strNumber: { stringValue: '4521/B/KKI/2014' },
        isRecommended: { booleanValue: true }
      }
    },
    {
      id: 'dr_dandi_wijaya',
      fields: {
        name: { stringValue: 'Dr. Dandi Wijaya' },
        specialty: { stringValue: 'Dokter Umum' },
        experienceYears: { integerValue: '5' },
        photoUrl: { stringValue: '' },
        price: { integerValue: '45000' },
        operatingHours: {
          arrayValue: {
            values: [
              { mapValue: { fields: { start: { stringValue: '09.00' }, end: { stringValue: '13.00' } } } }
            ]
          }
        },
        alumni: { stringValue: 'Universitas Gadjah Mada' },
        practiceLocation: { stringValue: 'Klinik Sehat Sentosa' },
        strNumber: { stringValue: '6789/C/KKI/2021' },
        isRecommended: { booleanValue: false }
      }
    }
  ];

  console.log('Memulai penulisan dokumen ke Firestore collection `doctors`...');
  for (const doc of doctors) {
    const data = JSON.stringify({ fields: doc.fields });
    const url = new URL(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/doctors/${doc.id}`);
    
    await new Promise((resolve, reject) => {
      const req = https.request(url, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data)
        }
      }, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            console.log(`✅ Sukses: Dokumen '${doc.id}' berhasil ditulis ke Firestore.`);
            resolve();
          } else {
            console.error(`❌ Gagal menulis '${doc.id}': Status ${res.statusCode} - ${body}`);
            reject(new Error(body));
          }
        });
      });
      req.on('error', reject);
      req.write(data);
      req.end();
    });
  }

  console.log('\n--- Verifikasi Koleksi `doctors` dari Firestore ---');
  const getUrl = new URL(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/doctors`);
  const listDocs = await new Promise((resolve, reject) => {
    https.get(getUrl, {
      headers: { 'Authorization': `Bearer ${token}` }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve(JSON.parse(body)));
    }).on('error', reject);
  });

  const count = listDocs.documents ? listDocs.documents.length : 0;
  console.log(`Ditemukan ${count} dokumen dokter di Firestore:`);
  if (listDocs.documents) {
    listDocs.documents.forEach((d, i) => {
      const id = d.name.split('/').pop();
      const f = d.fields;
      console.log(` [${i + 1}] ID: ${id}`);
      console.log(`     - Nama: ${f.name.stringValue}`);
      console.log(`     - Spesialisasi: ${f.specialty.stringValue}`);
      console.log(`     - Pengalaman: ${f.experienceYears.integerValue} tahun`);
      console.log(`     - Biaya: Rp ${f.price.integerValue}`);
      console.log(`     - Alumni: ${f.alumni.stringValue}`);
      console.log(`     - Lokasi Praktik: ${f.practiceLocation.stringValue}`);
      console.log(`     - Nomor STR: ${f.strNumber.stringValue}`);
      console.log(`     - Rekomendasi: ${f.isRecommended.booleanValue}`);
      console.log(`     - Jam Operasional: ${JSON.stringify(f.operatingHours.arrayValue.values.map(v => v.mapValue.fields.start.stringValue + ' - ' + v.mapValue.fields.end.stringValue))}`);
    });
  }
}

main().catch(err => {
  console.error('Fatal error saat seeding data:', err);
  process.exit(1);
});
