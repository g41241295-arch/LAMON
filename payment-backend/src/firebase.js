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

  if (saEnv && saEnv.trim().length > 0 && !saEnv.includes('placeholder')) {
    try {
      let parsed;
      const cleanSa = saEnv.trim();
      if (cleanSa.startsWith('{')) {
        parsed = JSON.parse(cleanSa);
      } else {
        const decoded = Buffer.from(cleanSa, 'base64').toString('utf8');
        parsed = JSON.parse(decoded);
      }
      credential = admin.credential.cert(parsed);
    } catch (err) {
      console.error('[Firebase] Gagal mem-parse FIREBASE_SERVICE_ACCOUNT:', err.message);
      throw new Error('Konfigurasi FIREBASE_SERVICE_ACCOUNT tidak valid (bukan JSON atau Base64 yang benar).');
    }
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    credential = admin.credential.applicationDefault();
  } else {
    throw new Error('FIREBASE_SERVICE_ACCOUNT belum dikonfigurasi pada environment backend.');
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
