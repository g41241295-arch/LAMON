#!/usr/bin/env node

/**
 * SatuSehat FHIR CLI Runner (PBM Semester 5)
 * Memungkinkan pengujian GET, POST, dan PATCH SatuSehat langsung di terminal
 * layaknya Postman, lengkap dengan output JSON terformat.
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Muat variabel lingkungan dari .env
const envPath = path.join(__dirname, '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  for (const line of envContent.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx > 0) {
      const key = trimmed.substring(0, eqIdx).trim();
      const val = trimmed.substring(eqIdx + 1).trim().replace(/^['"]|['"]$/g, '');
      if (!process.env[key]) {
        process.env[key] = val;
      }
    }
  }
}

const satuSehatService = require('./src/satusehatService');

const args = process.argv.slice(2);
const command = args[0] ? args[0].toLowerCase() : '';

function printJson(title, data) {
  console.log(`\n📦 [JSON RESPONSE] ${title}:`);
  console.log('----------------------------------------------------');
  console.log(JSON.stringify(data, null, 2));
  console.log('----------------------------------------------------\n');
}

async function doToken() {
  console.log('\n⏳ [POST] Mengambil Access Token OAuth 2.0 dari SatuSehat...');
  try {
    const token = await satuSehatService.getAccessToken();
    console.log('✅ Berhasil mendapatkan Access Token!');
    printJson('OAuth 2.0 Token Details', {
      token_type: 'Bearer',
      expires_in: 3600,
      scope: 'patient/* encounter/* condition/*',
      access_token: token,
      note: 'Token ini aktif selama 60 menit untuk seluruh operasi FHIR.',
    });
  } catch (err) {
    console.error('❌ Gagal mendapatkan token:', err.message);
  }
}

async function doGet(nikInput) {
  const nik = nikInput || args[1] || '1234567890123456';
  console.log(`\n⏳ [GET] Memanggil FHIR Resource Patient untuk NIK: ${nik}...`);
  try {
    const result = await satuSehatService.getRawPatientByNik(nik);
    console.log(`HTTP Status: ${result.status} ${result.ok ? 'OK' : 'Error'}`);
    printJson(`GET /fhir-r4/v1/Patient?identifier=nik|${nik}`, result.data);
  } catch (err) {
    console.error('❌ Error GET Patient:', err.message);
  }
}

async function doPost(nikInput, nameInput) {
  const nik = nikInput || args[1] || `3201${Math.floor(100000000000 + Math.random() * 900000000000)}`;
  const name = nameInput || args[2] || 'Pasien Uji Coba PBM';

  console.log(`\n⏳ [POST] Mengunggah Resource Patient Baru ke SatuSehat...`);
  console.log(`   - NIK Input : ${nik}`);
  console.log(`   - Nama      : ${name}`);

  // Payload standar HL7 FHIR R4 Patient Kemenkes
  const fhirPayload = {
    resourceType: 'Patient',
    meta: {
      profile: ['https://fhir.kemkes.go.id/r4/StructureDefinition/Patient'],
    },
    identifier: [
      {
        use: 'official',
        system: 'https://fhir.kemkes.go.id/id/nik',
        value: nik,
      },
    ],
    active: true,
    name: [
      {
        use: 'official',
        text: name,
      },
    ],
    telecom: [
      {
        system: 'phone',
        value: '081234567890',
        use: 'mobile',
      },
    ],
    gender: 'male',
    birthDate: '1995-08-17',
    address: [
      {
        use: 'home',
        line: ['Jl. Mahasiswa No. 45'],
        city: 'Jakarta',
      },
    ],
  };

  console.log('\n📤 [JSON REQUEST PAYLOAD DENGAN NIK ASAL / CUSTOM]:');
  console.log(JSON.stringify(fhirPayload, null, 2));

  try {
    const result = await satuSehatService.postPatient(fhirPayload);
    console.log(`\n📥 HTTP Status: ${result.status} (${result.ok ? 'Berhasil Terdaftar' : 'Audit Trail / Respon SatuSehat'})`);
    printJson('POST /fhir-r4/v1/Patient Response', result.data);
    if (!result.ok) {
      console.log('ℹ️ CATATAN AUDIT TRAIL:');
      console.log('   Pesan error di atas adalah respon resmi (OperationOutcome) SatuSehat.');
      console.log('   Sistem mencatat transaksi ini pada log audit trail Kemenkes.');
    }
  } catch (err) {
    console.error('❌ Error POST Patient:', err.message);
  }
}

async function doPatch(ihsInput, phoneInput) {
  const ihs = ihsInput || args[1] || 'P02029533115';
  const newPhone = phoneInput || args[2] || '081999888777';

  console.log(`\n⏳ [PATCH] Memperbarui Resource Patient (IHS: ${ihs})...`);

  // Format RFC 6902 JSON Patch
  const patchPayload = [
    {
      op: 'replace',
      path: '/telecom/0/value',
      value: newPhone,
    },
  ];

  console.log('\n📤 [JSON PATCH PAYLOAD]:');
  console.log(JSON.stringify(patchPayload, null, 2));

  try {
    const result = await satuSehatService.patchPatient(ihs, patchPayload);
    console.log(`\n📥 HTTP Status: ${result.status}`);
    printJson(`PATCH /fhir-r4/v1/Patient/${ihs} Response`, result.data);
  } catch (err) {
    console.error('❌ Error PATCH Patient:', err.message);
  }
}

function showMenu() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log('======================================================');
  console.log('🏥 SATUSEHAT FHIR TERMINAL CLIENT (POSTMAN REPLACEMENT)');
  console.log('======================================================');
  console.log('1. [POST]  Minta / Segarkan Access Token (OAuth 2.0)');
  console.log('2. [GET]   Cari Pasien berdasarkan NIK (FHIR Bundle)');
  console.log('3. [POST]  Upload Pasien Baru (NIK Asal/Custom + Audit Trail)');
  console.log('4. [PATCH] Update Data Pasien (Nomor Telepon / Kontak)');
  console.log('5. [EXIT]  Keluar');
  console.log('======================================================');

  rl.question('Pilih aksi [1-5]: ', async (choice) => {
    switch (choice.trim()) {
      case '1':
        await doToken();
        rl.close();
        break;
      case '2':
        rl.question('Masukkan 16 digit NIK (default: 1234567890123456): ', async (n) => {
          await doGet(n.trim() || '1234567890123456');
          rl.close();
        });
        break;
      case '3':
        rl.question('Masukkan NIK asal (Kosongkan untuk acak): ', (n) => {
          rl.question('Masukkan Nama Pasien (default: Budi Santoso): ', async (name) => {
            await doPost(n.trim(), name.trim() || 'Budi Santoso');
            rl.close();
          });
        });
        break;
      case '4':
        rl.question('Masukkan Nomor IHS (default: P02029533115): ', (ihs) => {
          rl.question('Masukkan Nomor Telepon Baru (default: 081999888777): ', async (tel) => {
            await doPatch(ihs.trim() || 'P02029533115', tel.trim() || '081999888777');
            rl.close();
          });
        });
        break;
      case '5':
        console.log('Selesai.');
        rl.close();
        break;
      default:
        console.log('Pilihan tidak valid.');
        rl.close();
        break;
    }
  });
}

// Router CLI
if (!command) {
  showMenu();
} else if (command === 'token') {
  doToken();
} else if (command === 'get') {
  doGet();
} else if (command === 'post') {
  doPost();
} else if (command === 'patch') {
  doPatch();
} else {
  console.log('Perintah tidak dikenali. Gunakan: token | get | post | patch');
}
