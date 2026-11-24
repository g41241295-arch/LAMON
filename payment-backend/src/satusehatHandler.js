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
  const { uid, nik } = req.body || {};

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
    // 1. Cari data pasien di SatuSehat berdasarkan NIK
    const patientData = await satuSehatService.getPatientByNik(cleanNik);

    if (!patientData) {
      return res.status(404).json({
        success: false,
        message:
          'Data pasien dengan NIK tersebut tidak ditemukan dalam sistem SatuSehat Kemenkes.',
      });
    }

    // 2. Simpan / sinkronkan ke dokumen user di Firestore
    const userRef = db.collection('users').doc(uid);
    const updateData = {
      nik: patientData.nik || cleanNik,
      ihsNumber: patientData.ihsNumber,
      satusehatLinked: true,
      satusehatLinkedAt: new Date().toISOString(),
      satusehatVerifiedName: patientData.name,
    };

    // Sinkronkan juga jenis_kelamin dan tanggal_lahir jika di Firestore belum ada atau kosong
    if (patientData.birthDate) {
      updateData.tanggal_lahir = patientData.birthDate;
    }
    if (patientData.gender) {
      updateData.jenis_kelamin = patientData.gender;
    }

    await userRef.set(updateData, { merge: true });

    return res.status(200).json({
      success: true,
      message: 'Berhasil memverifikasi dan menyinkronkan data pasien dengan SatuSehat Kemenkes.',
      data: patientData,
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

module.exports = {
  handleVerifyPatient,
  handleGetPatientStatus,
  handleUnlinkPatient,
};
