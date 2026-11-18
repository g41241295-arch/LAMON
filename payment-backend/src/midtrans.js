const crypto = require('crypto');

// URL Endpoint Sandbox Resmi Midtrans
// Dokumen: https://docs.midtrans.com/reference/create-snap-transaction
// Dokumen: https://docs.midtrans.com/reference/check-transaction-status
const SNAP_SANDBOX_BASE_URL = 'https://app.sandbox.midtrans.com/snap/v1';
const CORE_SANDBOX_BASE_URL = 'https://api.sandbox.midtrans.com/v2';

function getServerKey() {
  const key = process.env.MIDTRANS_SERVER_KEY;
  if (!key || key.trim() === '' || key.includes('YOUR_SERVER_KEY_HERE')) {
    throw new Error('MIDTRANS_SERVER_KEY belum dikonfigurasi di environment variable.');
  }
  return key.trim();
}

function getBasicAuthHeader() {
  const key = getServerKey();
  const base64Auth = Buffer.from(`${key}:`).toString('base64');
  return `Basic ${base64Auth}`;
}

/**
 * Membuat transaksi Snap baru di Midtrans Sandbox.
 * @param {Object} payload 
 * @returns {Promise<{token: string, redirect_url: string}>}
 */
async function createSnapTransaction(payload) {
  const url = `${SNAP_SANDBOX_BASE_URL}/transactions`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': getBasicAuthHeader(),
    },
    body: JSON.stringify(payload),
  });

  const data = await response.json();
  if (!response.ok) {
    const errorMsg = data?.error_messages ? data.error_messages.join(', ') : JSON.stringify(data);
    throw new Error(`Midtrans Snap API Error (${response.status}): ${errorMsg}`);
  }

  return data;
}

/**
 * Memeriksa status transaksi langsung ke Core API Midtrans Sandbox.
 * @param {string} orderId 
 * @returns {Promise<Object>}
 */
async function checkTransactionStatus(orderId) {
  const url = `${CORE_SANDBOX_BASE_URL}/${encodeURIComponent(orderId)}/status`;
  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'Accept': 'application/json',
      'Authorization': getBasicAuthHeader(),
    },
  });

  const data = await response.json();
  if (!response.ok) {
    const errorMsg = data?.status_message || JSON.stringify(data);
    throw new Error(`Midtrans Status API Error (${response.status}): ${errorMsg}`);
  }

  return data;
}

/**
 * Menghitung dan memvalidasi signature key Midtrans.
 * Rumus Resmi Midtrans:
 * SHA512(order_id + status_code + gross_amount + ServerKey)
 * Dokumen: https://docs.midtrans.com/reference/handling-notifications
 */
function verifySignatureKey({ order_id, status_code, gross_amount, signature_key }) {
  if (!order_id || !status_code || !gross_amount || !signature_key) {
    return false;
  }

  const serverKey = getServerKey();
  const rawString = `${order_id}${status_code}${gross_amount}${serverKey}`;
  const calculatedHash = crypto.createHash('sha512').update(rawString).digest('hex');

  return calculatedHash.toLowerCase() === String(signature_key).toLowerCase();
}

/**
 * Memetakan transaction_status dan fraud_status Midtrans ke paymentStatus LAMON.
 * Dokumen: https://docs.midtrans.com/reference/handling-notifications
 * @returns {'paid' | 'pending' | 'failed' | 'expired'}
 */
function mapMidtransStatus(transaction_status, fraud_status) {
  const status = (transaction_status || '').toLowerCase();
  const fraud = (fraud_status || '').toLowerCase();

  if (status === 'settlement') {
    return 'paid';
  }

  if (status === 'capture') {
    if (fraud === 'accept') {
      return 'paid';
    }
    if (fraud === 'challenge') {
      return 'pending';
    }
    return 'failed';
  }

  if (status === 'pending') {
    return 'pending';
  }

  if (status === 'deny' || status === 'cancel' || status === 'failure') {
    return 'failed';
  }

  if (status === 'expire') {
    return 'expired';
  }

  return 'pending';
}

module.exports = {
  createSnapTransaction,
  checkTransactionStatus,
  verifySignatureKey,
  mapMidtransStatus,
};
