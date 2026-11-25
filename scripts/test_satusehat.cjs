/**
 * Skrip Uji Coba Integrasi SatuSehat Kemenkes (HL7 FHIR R4)
 * Jalankan dari terminal dengan perintah:
 *   node scripts/test_satusehat.cjs [NIK_DUMMY]
 */

const fs = require('fs');
const path = require('path');

// Parser sederhana membaca file .env tanpa dependensi eksternal
const envPath = path.join(__dirname, '..', 'payment-backend', '.env');
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

const BASE_URL = process.env.SATUSEHAT_BASE_URL || 'https://api-satusehat-stg.dto.kemkes.go.id';
const CLIENT_ID = process.env.SATUSEHAT_CLIENT_ID;
const CLIENT_SECRET = process.env.SATUSEHAT_CLIENT_SECRET;
const TEST_NIK = process.argv[2] || '1234567890123456';

console.log('====================================================');
console.log('🚀 PENGUJIAN INTEGRASI SATUSEHAT KEMENKES (FHIR R4)');
console.log('====================================================');
console.log(`🌐 Base URL   : ${BASE_URL}`);
console.log(`🔑 Client ID  : ${CLIENT_ID ? CLIENT_ID.substring(0, 8) + '...' : '(KOSONG)'}`);
console.log(`🎯 Target NIK : ${TEST_NIK}`);
console.log('----------------------------------------------------\n');

async function run() {
  if (!CLIENT_ID || !CLIENT_SECRET) {
    console.error('❌ ERROR: SATUSEHAT_CLIENT_ID atau SATUSEHAT_CLIENT_SECRET belum diisi di payment-backend/.env');
    process.exit(1);
  }

  // ─── 1. METODE POST: MENDAPATKAN ACCESS TOKEN OAUTH 2.0 ───
  console.log('1️⃣ [POST] Meminta Access Token OAuth 2.0 ke SatuSehat...');
  const authUrl = `${BASE_URL}/oauth2/v1/accesstoken?grant_type=client_credentials`;
  const formParams = new URLSearchParams();
  formParams.append('client_id', CLIENT_ID.trim());
  formParams.append('client_secret', CLIENT_SECRET.trim());
  formParams.append('grant_type', 'client_credentials');

  let accessToken = '';
  try {
    const authRes = await fetch(authUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formParams.toString(),
    });
    const authData = await authRes.json();

    if (!authRes.ok) {
      console.error(`❌ Gagal OAuth (${authRes.status}):`, authData);
      process.exit(1);
    }

    accessToken = authData.access_token;
    console.log('   ✅ Berhasil mendapatkan Token!');
    console.log(`   🎟️  Token Type    : ${authData.token_type}`);
    console.log(`   ⏳ Berlaku Selama: ${authData.expires_in} detik (~1 jam)`);
    console.log(`   🔑 Token Preview : ${accessToken.substring(0, 35)}...\n`);
  } catch (err) {
    console.error('❌ Koneksi gagal:', err.message);
    process.exit(1);
  }

  // ─── 2. METODE GET: CARI DATA PASIEN VIA NIK ───
  console.log(`2️⃣ [GET] Mencari Resource FHIR Patient berdasarkan NIK: ${TEST_NIK}...`);
  const queryUrl = `${BASE_URL}/fhir-r4/v1/Patient?identifier=https://fhir.kemkes.go.id/id/nik|${TEST_NIK}`;

  let ihsNumber = '';
  try {
    const patientRes = await fetch(queryUrl, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/json',
      },
    });
    const patientBundle = await patientRes.json();

    if (!patientRes.ok) {
      console.error(`❌ Gagal Query Patient (${patientRes.status}):`, patientBundle);
      process.exit(1);
    }

    if (!patientBundle || patientBundle.total === 0 || !patientBundle.entry || patientBundle.entry.length === 0) {
      console.log(`⚠️ Pasien dengan NIK ${TEST_NIK} tidak ditemukan di database Sandbox SatuSehat.`);
      console.log('💡 Tips: Gunakan NIK dummy resmi Kemenkes: 1234567890123456 atau 1000000000000001\n');
      return;
    }

    const patient = patientBundle.entry[0].resource;
    ihsNumber = patient.id;

    console.log('   ✅ Pasien Ditemukan!');
    console.log(`   🏥 Resource Type : ${patient.resourceType}`);
    console.log(`   🆔 Nomor IHS     : ${ihsNumber}`);
    console.log(`   👤 Nama Lengkap  : ${patient.name?.[0]?.text || '(Tanpa Nama)'}`);
    console.log(`   ⚧  Jenis Kelamin : ${patient.gender || '-'}`);
    console.log(`   🎂 Tanggal Lahir : ${patient.birthDate || '-'}\n`);
  } catch (err) {
    console.error('❌ Gagal memanggil resource Patient:', err.message);
    process.exit(1);
  }

  // ─── 3. METODE GET: DETAIL PASIEN VIA IHS NUMBER ───
  if (ihsNumber) {
    console.log(`3️⃣ [GET] Mengambil Detail Pasien langsung via ID IHS: ${ihsNumber}...`);
    const ihsUrl = `${BASE_URL}/fhir-r4/v1/Patient/${ihsNumber}`;
    try {
      const ihsRes = await fetch(ihsUrl, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          Accept: 'application/json',
        },
      });
      const ihsData = await ihsRes.json();
      console.log('   ✅ Berhasil mengambil data pasien via ID IHS!');
      console.log(`   📋 Status Pasien : ${ihsData.active ? 'Aktif' : 'Tidak Aktif'}\n`);
    } catch (err) {
      console.error('❌ Gagal mengambil detail IHS:', err.message);
    }
  }

  // ─── 4. METODE POST KE ENDPOINT BACKEND APLIKASI KITA ───
  console.log('4️⃣ [POST] Menguji Endpoint Backend Aplikasi (/api/satusehat/verify-patient)...');
  const backendUrl = 'https://payment-backend-omega-five.vercel.app/api/satusehat/verify-patient';
  try {
    const backendRes = await fetch(backendUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        uid: 'demo-cli-user',
        nik: TEST_NIK,
      }),
    });
    const backendData = await backendRes.json();
    console.log('   ✅ Respons Backend:', JSON.stringify(backendData, null, 2));
  } catch (err) {
    console.error('❌ Gagal menguji backend:', err.message);
  }

  console.log('\n====================================================');
  console.log('🎉 SEMUA PENGUJIAN SATUSEHAT BERJALAN DENGAN SUKSES!');
  console.log('====================================================');
}

run();
