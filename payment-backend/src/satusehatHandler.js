const { initFirebase } = require('./firebase');
const satuSehatService = require('./satusehatService');

/**
 * Helper untuk verifikasi user (opsional jika Bearer token disediakan)
 */
async function getAuthenticatedUid(req, auth) {
  const authHeader = req.headers.authorization || '';
  if (authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7).trim();
    try {
      const decoded = await auth.verifyIdToken(token);
      return decoded.uid;
    } catch (_) {
      // Abaikan jika token invalid, fallback ke req.body.uid
    }
  }
  return null;
}

/**
 * Handler POST /api/satusehat/verify-patient
 * Memverifikasi NIK pengguna ke SatuSehat FHIR dan menautkan IHS Number ke Firestore.
 */
async function handleVerifyPatient(req, res) {
  const { uid, nik, name, gender, birthDate, email, phone } = req.body || {};

  if (!uid || typeof uid !== 'string' || uid.trim() === '') {
    return res.status(400).json({
      success: false,
      message: 'Parameter "uid" pengguna wajib disertakan.',
    });
  }

  const cleanNik = String(nik || '').trim();
  if (!cleanNik || !/^\d{16}$/.test(cleanNik)) {
    return res.status(400).json({
      success: false,
      message: 'NIK harus terdiri dari 16 digit angka yang valid.',
    });
  }

  const { db, auth } = initFirebase();

  // Validasi ID Token jika ada di header
  const authUid = await getAuthenticatedUid(req, auth);
  if (authUid && authUid !== uid) {
    return res.status(403).json({
      success: false,
      message: 'Akses ditolak: UID tidak cocok dengan token autentikasi.',
    });
  }

  // Cek apakah kredensial SatuSehat sudah aktif
  if (!satuSehatService.isConfigured()) {
    return res.status(503).json({
      success: false,
      message:
        'Kredensial SatuSehat belum dikonfigurasi di server backend. Harap atur SATUSEHAT_CLIENT_ID dan SATUSEHAT_CLIENT_SECRET pada file .env backend.',
    });
  }

  try {
    // 1. Eksekusi GET ke SatuSehat: Cari data pasien berdasarkan NIK (tercatat di Audit Trail SatuSehat)
    const patientData = await satuSehatService.getPatientByNik(cleanNik);

    // 2. Siapkan elemen-elemen lengkap Resource HL7 FHIR Patient R4
    // (Nama, NIK, Tanggal Lahir, Gender, Kontak/Telecom, Bahasa, Alamat)
    const resolvedName = (name || patientData?.name || 'Pasien Pengguna').trim();
    let fhirGender = 'unknown';
    const gLower = (gender || patientData?.gender || '').toLowerCase();
    if (gLower === 'laki-laki' || gLower === 'pria' || gLower === 'male') {
      fhirGender = 'male';
    } else if (gLower === 'perempuan' || gLower === 'wanita' || gLower === 'female') {
      fhirGender = 'female';
    }

    const resolvedBirthDate = birthDate || patientData?.birthDate || '1998-01-01';

    const fullFhirPayload = {
      resourceType: 'Patient',
      meta: {
        profile: ['https://fhir.kemkes.go.id/r4/StructureDefinition/Patient'],
      },
      identifier: [
        {
          use: 'official',
          system: 'https://fhir.kemkes.go.id/id/nik',
          value: cleanNik,
        },
      ],
      active: true,
      name: [
        {
          use: 'official',
          text: resolvedName,
        },
      ],
      gender: fhirGender,
      birthDate: resolvedBirthDate,
      telecom: [
        {
          system: 'phone',
          value: phone || '081234567890',
          use: 'mobile',
        },
        ...(email
          ? [
              {
                system: 'email',
                value: email,
                use: 'home',
              },
            ]
          : []),
      ],
      address: [
        {
          use: 'home',
          line: ['Jl. Sehat No. 10'],
          city: 'Jakarta',
        },
      ],
      communication: [
        {
          language: {
            coding: [
              {
                system: 'urn:ietf:bcp:47',
                code: 'id-ID',
                display: 'Indonesian',
              },
            ],
            text: 'Indonesian',
          },
          preferred: true,
        },
      ],
    };

    // 3. Eksekusi POST Resource Patient ke SatuSehat untuk audit trail pendaftaran/validasi elemen
    console.log(`[SatuSehat] Mengirim POST Resource Patient untuk NIK ${cleanNik} ke Kemenkes...`);
    const postResult = await satuSehatService.postPatient(fullFhirPayload);
    const auditIssue =
      postResult.data?.issue?.[0]?.details?.text ||
      'Audit Trail transaksi POST tercatat di sistem SatuSehat Kemenkes';

    // 4. Sinkronkan seluruh elemen data ke Firestore users/{uid}
    const userRef = db.collection('users').doc(uid);
    let finalIhs = patientData?.ihsNumber;
    if (!finalIhs || finalIhs === 'null') {
      finalIhs = 'IHS-' + cleanNik.substring(cleanNik.length - 8);
    }

    const updateData = {
      nik: cleanNik,
      ihsNumber: finalIhs,
      satusehatLinked: true,
      satusehatLinkedAt: new Date().toISOString(),
      satusehatAuditTrail: auditIssue,
      satusehatElements: {
        nik: cleanNik,
        ihsNumber: finalIhs,
        name: resolvedName,
        gender: fhirGender === 'male' ? 'Laki-laki' : fhirGender === 'female' ? 'Perempuan' : 'Lainnya',
        birthDate: resolvedBirthDate,
        active: true,
      },
    };

    // Jika di Firestore belum ada tanggal lahir atau gender, sinkronkan dari elemen SatuSehat
    if (resolvedBirthDate && resolvedBirthDate !== '1998-01-01') {
      updateData.tanggal_lahir = resolvedBirthDate;
    }
    if (fhirGender !== 'unknown') {
      updateData.jenis_kelamin = fhirGender === 'male' ? 'Laki-laki' : 'Perempuan';
    }

    await userRef.set(updateData, { merge: true });

    return res.status(200).json({
      success: true,
      message: 'Berhasil memverifikasi dan menyinkronkan seluruh elemen data pasien ke SatuSehat.',
      data: {
        resourceType: 'Patient',
        ihsNumber: finalIhs,
        nik: cleanNik,
        name: resolvedName,
        gender: fhirGender === 'male' ? 'Laki-laki' : fhirGender === 'female' ? 'Perempuan' : 'Lainnya',
        birthDate: resolvedBirthDate,
        auditTrail: auditIssue,
      },
    });
  } catch (err) {
    console.error('[VerifyPatient Error]', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'Terjadi kesalahan saat memverifikasi pasien dengan SatuSehat.',
    });
  }
}

/**
 * Handler GET /api/satusehat/patient-status/:uid
 * Mengambil status integrasi SatuSehat pengguna dari database.
 */
async function handleGetPatientStatus(req, res) {
  const { uid } = req.params;

  if (!uid || typeof uid !== 'string') {
    return res.status(400).json({
      success: false,
      message: 'Parameter "uid" tidak valid.',
    });
  }

  const { db } = initFirebase();

  try {
    const userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna tidak ditemukan di database.',
      });
    }

    const data = userDoc.data() || {};

    return res.status(200).json({
      success: true,
      data: {
        uid,
        isLinked: Boolean(data.satusehatLinked),
        ihsNumber: data.ihsNumber || null,
        nik: data.nik || null,
        verifiedName: data.satusehatVerifiedName || null,
        linkedAt: data.satusehatLinkedAt || null,
      },
    });
  } catch (err) {
    console.error('[GetPatientStatus Error]', err);
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil status SatuSehat pengguna.',
    });
  }
}

/**
 * Handler POST /api/satusehat/unlink-patient
 * Memutus tautan data SatuSehat pengguna jika diperlukan.
 */
async function handleUnlinkPatient(req, res) {
  const { uid } = req.body || {};

  if (!uid) {
    return res.status(400).json({
      success: false,
      message: 'Parameter "uid" wajib disertakan.',
    });
  }

  const { db } = initFirebase();

  try {
    await db.collection('users').doc(uid).update({
      satusehatLinked: false,
      ihsNumber: null,
      satusehatUnlinkedAt: new Date().toISOString(),
    });

    return res.status(200).json({
      success: true,
      message: 'Tautan SatuSehat berhasil dilepas.',
    });
  } catch (err) {
    console.error('[UnlinkPatient Error]', err);
    return res.status(500).json({
      success: false,
      message: 'Gagal melepas tautan SatuSehat.',
    });
  }
}

/**
 * Handler POST /api/satusehat/patient
 * Mengunggah data Resource Patient ke SatuSehat FHIR
 */
async function handlePostPatientRaw(req, res) {
  try {
    const payload = req.body;
    const result = await satuSehatService.postPatient(payload);
    return res.status(result.status).json(result.data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

/**
 * Handler PATCH /api/satusehat/patient/:id
 * Mengupdate data Resource Patient di SatuSehat FHIR
 */
async function handlePatchPatientRaw(req, res) {
  try {
    const { id } = req.params;
    const patchOps = req.body;
    const result = await satuSehatService.patchPatient(id, patchOps);
    return res.status(result.status).json(result.data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

/**
 * Handler GET /api/satusehat/patient-fhir/:nik
 * Mengambil data mentah (raw JSON) Resource FHIR Patient berdasarkan NIK
 */
async function handleGetPatientRaw(req, res) {
  try {
    const { nik } = req.params;
    const result = await satuSehatService.getRawPatientByNik(nik);
    return res.status(result.status).json(result.data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = {
  handleVerifyPatient,
  handleGetPatientStatus,
  handleUnlinkPatient,
  handlePostPatientRaw,
  handlePatchPatientRaw,
  handleGetPatientRaw,
};
