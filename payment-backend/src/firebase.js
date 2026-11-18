const admin = require('firebase-admin');

let initialized = false;

function initFirebase() {
  if (initialized || admin.apps.length > 0) {
    return {
      admin,
      db: admin.firestore(),
      auth: admin.auth(),
    };
  }

  const saEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
  let credential;

  if (saEnv) {
    try {
      let parsed;
      if (saEnv.trim().startsWith('{')) {
        parsed = JSON.parse(saEnv);
      } else {
        const decoded = Buffer.from(saEnv, 'base64').toString('utf8');
        parsed = JSON.parse(decoded);
      }
      credential = admin.credential.cert(parsed);
    } catch (err) {
      console.error('[Firebase] Gagal mem-parse FIREBASE_SERVICE_ACCOUNT:', err.message);
      throw new Error('Konfigurasi FIREBASE_SERVICE_ACCOUNT tidak valid (bukan JSON atau Base64 yang benar).');
    }
  } else {
    // Fallback: coba kredensial default lingkungan (misalnya ADC)
    credential = admin.credential.applicationDefault();
  }

  admin.initializeApp({ credential });
  initialized = true;

  return {
    admin,
    db: admin.firestore(),
    auth: admin.auth(),
  };
}

module.exports = { initFirebase };
