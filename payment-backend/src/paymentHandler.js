const { initFirebase } = require('./firebase');
const {
  createSnapTransaction,
  checkTransactionStatus,
  verifySignatureKey,
  mapMidtransStatus,
} = require('./midtrans');

const SERVICE_FEE = 10000; // Biaya layanan aplikasi resmi LAMON

/**
 * Ekstrak dan verifikasi Firebase Auth ID Token dari header Authorization.
 */
async function authenticateUser(req, auth) {
  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) {
    throw { status: 401, message: 'Header Authorization: Bearer <token> diperlukan.' };
  }
  const token = authHeader.substring(7).trim();
  try {
    const decoded = await auth.verifyIdToken(token);
    return decoded;
  } catch (err) {
    throw { status: 401, message: `Autentikasi gagal: ${err.message}` };
  }
}

/**
 * Format tanggal ke format start_time Midtrans: "yyyy-MM-dd HH:mm:ss +0700"
 */
function formatMidtransTime(date) {
  const pad = (n) => String(n).padStart(2, '0');
  const y = date.getFullYear();
  const m = pad(date.getMonth() + 1);
  const d = pad(date.getDate());
  const hh = pad(date.getHours());
  const mm = pad(date.getMinutes());
  const ss = pad(date.getSeconds());
  return `${y}-${m}-${d} ${hh}:${mm}:${ss} +0700`;
}

/**
 * Handler POST /api/create-transaction
 */
async function handleCreateTransaction(req, res) {
  const { db, auth, admin } = initFirebase();
  const user = await authenticateUser(req, auth);
  const uid = user.uid;

  const { consultationId } = req.body || {};
  if (!consultationId || typeof consultationId !== 'string') {
    return res.status(400).json({ error: 'Field consultationId (string) wajib disertakan.' });
  }

  // 1. Ambil dokumen konsultasi dari users/{uid}/consultations/{consultationId}
  const consultRef = db.collection('users').doc(uid).collection('consultations').doc(consultationId);
  const consultSnap = await consultRef.get();

  if (!consultSnap.exists) {
    return res.status(404).json({ error: 'Konsultasi tidak ditemukan atau bukan milik akun Anda.' });
  }

  const consultData = consultSnap.data();

  // Validasi kepemilikan dan status
  if (consultData.patientUid && consultData.patientUid !== uid) {
    return res.status(403).json({ error: 'Akses ditolak: Anda bukan pemilik konsultasi ini.' });
  }

  if (consultData.paymentStatus === 'paid') {
    return res.status(400).json({ error: 'Konsultasi ini sudah dibayar (status: paid).' });
  }

  const now = new Date();
  const paymentExpiresAt = consultData.paymentExpiresAt?.toDate
    ? consultData.paymentExpiresAt.toDate()
    : (consultData.paymentDeadline?.toDate ? consultData.paymentDeadline.toDate() : null);

  if (paymentExpiresAt && paymentExpiresAt < now) {
    return res.status(400).json({ error: 'Batas waktu pembayaran untuk konsultasi ini telah habis.' });
  }

  // 2. Ambil harga resmi dokter dari Firestore (dokumen doctors/{doctorId})
  const doctorId = consultData.doctorId;
  let sessionFee = Number(consultData.sessionFee) || 45000;

  if (doctorId) {
    try {
      const docSnap = await db.collection('doctors').doc(doctorId).get();
      if (docSnap.exists) {
        const docData = docSnap.data();
        if (docData.price && typeof docData.price === 'number') {
          sessionFee = docData.price;
        }
      }
    } catch (e) {
      console.warn('[CreateTransaction] Peringatan membaca data dokter, menggunakan sessionFee tersimpan:', e.message);
    }
  }

  const totalFee = Math.round(sessionFee + SERVICE_FEE);

  // 3. Cek apakah sudah ada order aktif yang pending untuk konsultasi ini (Idempoten per booking)
  const existingPaymentsSnap = await db.collection('payments')
    .where('consultationId', '==', consultationId)
    .where('status', '==', 'pending')
    .limit(1)
    .get();

  if (!existingPaymentsSnap.empty) {
    const existingPayment = existingPaymentsSnap.docs[0].data();
    if (existingPayment.redirectUrl && existingPayment.orderId) {
      console.log(`[CreateTransaction] Menggunakan kembali order aktif: ${existingPayment.orderId}`);
      return res.status(200).json({
        success: true,
        orderId: existingPayment.orderId,
        redirectUrl: existingPayment.redirectUrl,
        token: existingPayment.token || null,
        reused: true,
      });
    }
  }

  // 4. Buat order_id unik
  const timestamp = Date.now();
  const orderId = `LAMON-${consultationId.substring(0, 10)}-${timestamp}`;

  // Hitung sisa waktu kedaluwarsa (dalam menit, minimal 5 menit, maksimal 60 menit)
  let remainingMinutes = 60;
  if (paymentExpiresAt) {
    const diffMs = paymentExpiresAt.getTime() - now.getTime();
    remainingMinutes = Math.max(5, Math.min(60, Math.floor(diffMs / (60 * 1000))));
  }

  // Data pelanggan
  const customerName = (consultData.patientName || user.name || 'Pasien LAMON').trim();
  const customerEmail = (user.email || 'pasien@lamon.app').trim();

  // 5. Susun payload Snap Midtrans sesuai dokumentasi resmi
  const snapPayload = {
    transaction_details: {
      order_id: orderId,
      gross_amount: totalFee,
    },
    item_details: [
      {
        id: `doctor_session_${doctorId || 'general'}`,
        price: sessionFee,
        quantity: 1,
        name: `Sesi ${consultData.doctorName || 'Dokter Spesialis'}`.substring(0, 50),
      },
      {
        id: 'service_fee',
        price: SERVICE_FEE,
        quantity: 1,
        name: 'Biaya Layanan Aplikasi LAMON',
      },
    ],
    customer_details: {
      first_name: customerName,
      email: customerEmail,
    },
    expiry: {
      start_time: formatMidtransTime(now),
      unit: 'minutes',
      duration: remainingMinutes,
    },
    callbacks: {
      finish: 'https://lamon.app/payment-finish',
    },
  };

  console.log(`[CreateTransaction] Memanggil Snap Sandbox untuk orderId: ${orderId}, total: Rp${totalFee}`);
  const snapResponse = await createSnapTransaction(snapPayload);

  // 6. Simpan dokumen payments/{orderId} di Firestore
  await db.collection('payments').doc(orderId).set({
    orderId,
    consultationId,
    uid,
    amount: totalFee,
    status: 'pending',
    redirectUrl: snapResponse.redirect_url,
    token: snapResponse.token,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: paymentExpiresAt || new Date(now.getTime() + remainingMinutes * 60 * 1000),
  });

  // 7. Perbarui status consultation menjadi 'pending' dengan paymentOrderId
  await consultRef.update({
    paymentStatus: 'pending',
    paymentOrderId: orderId,
    paymentMethodName: 'Midtrans Snap',
  });

  return res.status(200).json({
    success: true,
    orderId,
    redirectUrl: snapResponse.redirect_url,
    token: snapResponse.token,
  });
}

/**
 * Logika bersama untuk memproses update status pembayaran ke Firestore secara idempoten.
 */
async function applyPaymentUpdate({ db, admin, orderId, notificationData }) {
  const {
    transaction_status,
    fraud_status,
    gross_amount,
    payment_type,
    settlement_time,
  } = notificationData;

  const mappedStatus = mapMidtransStatus(transaction_status, fraud_status);
  console.log(`[PaymentUpdate] orderId: ${orderId}, transaction_status: ${transaction_status}, mapped: ${mappedStatus}`);

  const paymentRef = db.collection('payments').doc(orderId);

  return await db.runTransaction(async (transaction) => {
    const paymentDoc = await transaction.get(paymentRef);
    if (!paymentDoc.exists) {
      console.warn(`[PaymentUpdate] Dokumen payments/${orderId} tidak ditemukan.`);
      return { skipped: true, reason: 'order_not_found' };
    }

    const payment = paymentDoc.data();
    const { consultationId, uid, amount } = payment;

    // Validasi kecocokan nominal jika ada gross_amount
    if (gross_amount && Math.round(Number(gross_amount)) !== Math.round(Number(amount))) {
      console.error(`[PaymentUpdate] Nominal tidak cocok untuk order ${orderId}: expected ${amount}, got ${gross_amount}`);
      return { error: 'nominal_mismatch' };
    }

    const consultRef = db.collection('users').doc(uid).collection('consultations').doc(consultationId);
    const consultDoc = await transaction.get(consultRef);

    if (!consultDoc.exists) {
      console.warn(`[PaymentUpdate] Dokumen konsultasi ${consultationId} tidak ditemukan.`);
      return { skipped: true, reason: 'consultation_not_found' };
    }

    const consult = consultDoc.data();

    // Idempotensi: Jika sudah 'paid', status tidak boleh mundur
    if (consult.paymentStatus === 'paid' && mappedStatus === 'paid') {
      console.log(`[PaymentUpdate] Konsultasi ${consultationId} sudah berstatus paid (idempoten).`);
      return { success: true, alreadyPaid: true };
    }

    const now = new Date();
    const paymentExpiresAt = consult.paymentExpiresAt?.toDate
      ? consult.paymentExpiresAt.toDate()
      : (consult.paymentDeadline?.toDate ? consult.paymentDeadline.toDate() : null);

    const paymentUpdateData = {
      status: mappedStatus,
      paymentType: payment_type || payment.paymentType || 'midtrans',
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (mappedStatus === 'paid') {
      paymentUpdateData.paidAt = admin.firestore.FieldValue.serverTimestamp();

      // Kasus tepi: Pembayaran settle setelah batas waktu kedaluwarsa di aplikasi
      if (paymentExpiresAt && paymentExpiresAt < now && consult.paymentStatus === 'expired') {
        console.warn(`[PaymentUpdate] Kasus tepi: Pembayaran ${orderId} lunas setelah kedaluwarsa!`);
        transaction.update(consultRef, {
          paymentStatus: 'paid_after_expiry',
          paymentOrderId: orderId,
          paymentType: payment_type || 'midtrans',
          paymentGrossAmount: Math.round(Number(gross_amount || amount)),
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.update(paymentRef, paymentUpdateData);
        return { success: true, status: 'paid_after_expiry' };
      }

      // Alur normal lunas:
      // Pindahkan paymentStatus ke 'paid', dan status ke 'waiting' (menunggu konfirmasi dokter)
      transaction.update(consultRef, {
        paymentStatus: 'paid',
        status: 'waiting',
        paymentOrderId: orderId,
        paymentType: payment_type || 'midtrans',
        paymentGrossAmount: Math.round(Number(gross_amount || amount)),
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.update(paymentRef, paymentUpdateData);
      return { success: true, status: 'paid' };
    } else {
      // Status failed atau expired
      transaction.update(consultRef, {
        paymentStatus: mappedStatus,
      });
      transaction.update(paymentRef, paymentUpdateData);
      return { success: true, status: mappedStatus };
    }
  });
}

/**
 * Handler POST /api/midtrans-webhook
 */
async function handleWebhook(req, res) {
  const { db, admin } = initFirebase();
  const notification = req.body;

  if (!notification || typeof notification !== 'object') {
    return res.status(400).json({ error: 'Payload notification tidak valid.' });
  }

  const { order_id, status_code, gross_amount, signature_key } = notification;

  // 1. Verifikasi signature_key
  const isValid = verifySignatureKey({
    order_id,
    status_code,
    gross_amount,
    signature_key,
  });

  if (!isValid) {
    console.error(`[Webhook] Signature tidak valid untuk order_id: ${order_id}`);
    return res.status(403).json({ error: 'Signature key tidak valid.' });
  }

  // 2. Cek apakah order dikenal
  const paymentDoc = await db.collection('payments').doc(order_id).get();
  if (!paymentDoc.exists) {
    // Tombol tes notifikasi di Dashboard Midtrans sering mengirim order ID dummy
    console.log(`[Webhook] Order ID tidak ditemukan di payments: ${order_id} (notifikasi tes diakui 200).`);
    return res.status(200).json({ status: 'ok', message: 'Test notification acknowledged' });
  }

  // 3. Terapkan update secara idempoten
  try {
    const result = await applyPaymentUpdate({
      db,
      admin,
      orderId: order_id,
      notificationData: notification,
    });

    if (result?.error === 'nominal_mismatch') {
      return res.status(400).json({ error: 'Gross amount tidak cocok dengan data tersimpan.' });
    }

    return res.status(200).json({ status: 'ok', result });
  } catch (err) {
    console.error(`[Webhook] Gagal memproses update pembayaran ${order_id}:`, err);
    return res.status(500).json({ error: 'Gagal memproses notifikasi.' });
  }
}

/**
 * Handler POST /api/check-payment
 */
async function handleCheckPayment(req, res) {
  const { db, auth, admin } = initFirebase();
  const user = await authenticateUser(req, auth);
  const uid = user.uid;

  const { consultationId } = req.body || {};
  if (!consultationId || typeof consultationId !== 'string') {
    return res.status(400).json({ error: 'Field consultationId (string) wajib disertakan.' });
  }

  // 1. Ambil dokumen konsultasi
  const consultRef = db.collection('users').doc(uid).collection('consultations').doc(consultationId);
  const consultSnap = await consultRef.get();

  if (!consultSnap.exists) {
    return res.status(404).json({ error: 'Konsultasi tidak ditemukan.' });
  }

  const consultData = consultSnap.data();

  // 2. Ambil paymentOrderId
  let orderId = consultData.paymentOrderId;

  if (!orderId) {
    // Cari di koleksi payments
    const paymentQuery = await db.collection('payments')
      .where('consultationId', '==', consultationId)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (paymentQuery.empty) {
      return res.status(404).json({ error: 'Belum ada transaksi pembayaran yang dibuat untuk konsultasi ini.' });
    }
    orderId = paymentQuery.docs[0].id;
  }

  console.log(`[CheckPayment] Memeriksa status transaksi ke Midtrans untuk orderId: ${orderId}`);

  // 3. Panggil API get status Midtrans
  let statusResponse;
  try {
    statusResponse = await checkTransactionStatus(orderId);
  } catch (e) {
    return res.status(502).json({ error: `Gagal menghubungi server Midtrans: ${e.message}` });
  }

  // 4. Terapkan pembaruan yang SAMA dengan webhook
  try {
    const updateResult = await applyPaymentUpdate({
      db,
      admin,
      orderId,
      notificationData: statusResponse,
    });

    // Ambil status terbaru
    const updatedConsultSnap = await consultRef.get();
    const updatedStatus = updatedConsultSnap.data()?.paymentStatus || 'pending';

    return res.status(200).json({
      success: true,
      orderId,
      paymentStatus: updatedStatus,
      rawStatus: statusResponse.transaction_status,
      updateResult,
    });
  } catch (err) {
    console.error(`[CheckPayment] Error applying payment update for ${orderId}:`, err);
    return res.status(500).json({ error: 'Gagal memperbarui status konsultasi.' });
  }
}

module.exports = {
  handleCreateTransaction,
  handleWebhook,
  handleCheckPayment,
};
