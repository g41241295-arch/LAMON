const admin = require('firebase-admin');

// Inisialisasi Firebase Admin SDK secara singleton dari environment variable FIREBASE_SERVICE_ACCOUNT
if (!admin.apps.length) {
  const serviceAccountRaw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!serviceAccountRaw) {
    console.error('FIREBASE_SERVICE_ACCOUNT environment variable is not set.');
  } else {
    try {
      const serviceAccount = JSON.parse(serviceAccountRaw);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } catch (e) {
      console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', e.message);
    }
  }
}

module.exports = async function handler(req, res) {
  // ── e. Tangani CORS (OPTIONS & headers) ─────────────────────────────────────
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!admin.apps.length) {
    return res.status(500).json({ error: 'Relay server misconfigured: Firebase Admin not initialized' });
  }

  try {
    // ── a. Verifikasi Firebase ID token ──────────────────────────────────────
    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }

    const idToken = authHeader.split('Bearer ')[1].trim();
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired ID token' });
    }

    const callerUid = decodedToken.uid;

    const { patientUid, consultationId } = req.body || {};
    if (!patientUid || !consultationId) {
      return res.status(400).json({ error: 'patientUid and consultationId are required' });
    }

    const db = admin.firestore();

    // ── b. Baca users/{patientUid}/consultations/{consultationId} ───────────
    const consultationDoc = await db
      .collection('users')
      .doc(patientUid)
      .collection('consultations')
      .doc(consultationId)
      .get();

    if (!consultationDoc.exists) {
      return res.status(404).json({ error: 'Consultation document not found' });
    }

    const consultationData = consultationDoc.data() || {};
    const doctorId = consultationData.doctorId;
    if (!doctorId) {
      return res.status(400).json({ error: 'Consultation missing doctorId' });
    }

    // ── c. Tentukan pengirim dan penerima ────────────────────────────────────
    let senderName = 'LAMON';
    let recipientUid = null;
    let recipientRole = null;

    if (callerUid === patientUid) {
      // Pengirim adalah Pasien -> Penerima adalah Dokter
      // Cari dokumen user dokter di mana users.doctorId == consultation.doctorId dan role in ['doctor', 'dokter']
      const doctorUserQuery = await db
        .collection('users')
        .where('doctorId', '==', doctorId)
        .limit(5)
        .get();

      let targetDoc = null;
      for (const d of doctorUserQuery.docs) {
        const udata = d.data();
        const role = (udata.role || '').toLowerCase();
        if (role === 'doctor' || role === 'dokter') {
          targetDoc = d;
          break;
        }
      }

      if (!targetDoc) {
        // Coba cari alternatif field doctor_id
        const altQuery = await db
          .collection('users')
          .where('doctor_id', '==', doctorId)
          .limit(5)
          .get();
        for (const d of altQuery.docs) {
          const udata = d.data();
          const role = (udata.role || '').toLowerCase();
          if (role === 'doctor' || role === 'dokter') {
            targetDoc = d;
            break;
          }
        }
      }

      if (!targetDoc) {
        return res.status(404).json({ error: 'Recipient doctor user not found' });
      }

      recipientUid = targetDoc.id;
      recipientRole = 'doctor';

      // Nama pengirim untuk judul notifikasi
      senderName = consultationData.patientName || decodedToken.name || 'Pasien';
    } else {
      // Pengirim bukan Pasien -> harus merupakan Dokter yang bersangkutan
      const callerUserDoc = await db.collection('users').doc(callerUid).get();
      if (!callerUserDoc.exists) {
        return res.status(403).json({ error: 'Caller user record not found' });
      }

      const callerData = callerUserDoc.data() || {};
      const callerDocId = callerData.doctorId || callerData.doctor_id;
      const callerRole = (callerData.role || '').toLowerCase();

      if ((callerRole !== 'doctor' && callerRole !== 'dokter') || callerDocId !== doctorId) {
        return res.status(403).json({ error: 'Caller is not authorized for this consultation' });
      }

      // Pengirim adalah Dokter -> Penerima adalah Pasien
      recipientUid = patientUid;
      recipientRole = 'patient';

      // Nama pengirim untuk judul notifikasi
      senderName = consultationData.doctorName || callerData.name || 'Dokter';
    }

    // ── d. Baca users/{recipientUid}.fcmTokens & kirim FCM ──────────────────
    const recipientDoc = await db.collection('users').doc(recipientUid).get();
    if (!recipientDoc.exists) {
      return res.status(404).json({ error: 'Recipient user document not found' });
    }

    const recipientData = recipientDoc.data() || {};
    const rawTokens = recipientData.fcmTokens || [];
    const tokens = Array.isArray(rawTokens)
      ? rawTokens.filter((t) => typeof t === 'string' && t.trim().length > 0)
      : [];

    if (tokens.length === 0) {
      return res.status(200).json({
        success: true,
        delivered: 0,
        message: 'Recipient has no registered FCM tokens',
      });
    }

    // Siapkan multicast message
    // PRIVASI: isi pesan TIDAK dikirim ke relay dan TIDAK ditampilkan di notifikasi.
    // Judul = nama pengirim, isi generik "Pesan baru".
    // Payload data hanya berisi ID teknis.
    const messagePayload = {
      tokens: tokens,
      notification: {
        title: senderName,
        body: 'Pesan baru',
      },
      data: {
        consultationId: String(consultationId),
        patientUid: String(patientUid),
        recipientRole: String(recipientRole),
        type: 'chat',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_messages',
          priority: 'high',
          defaultSound: true,
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(messagePayload);

    // Hapus token yang tidak valid jika ada
    const tokensToRemove = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errCode = resp.error?.code || '';
        if (
          errCode === 'messaging/registration-token-not-registered' ||
          errCode === 'messaging/invalid-registration-token'
        ) {
          tokensToRemove.push(tokens[idx]);
        }
      }
    });

    if (tokensToRemove.length > 0) {
      await db
        .collection('users')
        .doc(recipientUid)
        .update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
        });
    }

    return res.status(200).json({
      success: true,
      delivered: response.successCount,
      failed: response.failureCount,
    });
  } catch (err) {
    console.error('Relay error:', err.message);
    return res.status(500).json({ error: 'Internal relay error' });
  }
};
