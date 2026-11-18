require('dotenv').config();
const express = require('express');
const cors = require('cors');
const {
  handleCreateTransaction,
  handleWebhook,
  handleCheckPayment,
} = require('./paymentHandler');

const app = express();

// Konfigurasi CORS
const allowedOrigins = process.env.PAYMENT_ALLOWED_ORIGINS
  ? process.env.PAYMENT_ALLOWED_ORIGINS.split(',').map((s) => s.trim())
  : ['*'];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Origin tidak diizinkan oleh CORS'));
    },
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'online',
    service: 'LAMON Payment Backend (Midtrans Snap Sandbox)',
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Endpoint Health Check Publik dengan Verifikasi Status Lingkungan
app.get('/api/health', (req, res) => {
  const midtransKey = Boolean(
    process.env.MIDTRANS_SERVER_KEY &&
    process.env.MIDTRANS_SERVER_KEY.trim() !== '' &&
    !process.env.MIDTRANS_SERVER_KEY.includes('YOUR_SERVER_KEY')
  );

  let firebaseAdmin = false;
  const saEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (saEnv && saEnv.trim() !== '' && !saEnv.includes('placeholder')) {
    try {
      const clean = saEnv.trim();
      if (clean.startsWith('{')) {
        JSON.parse(clean);
        firebaseAdmin = true;
      } else {
        const decoded = Buffer.from(clean, 'base64').toString('utf8');
        JSON.parse(decoded);
        firebaseAdmin = true;
      }
    } catch (_) {
      firebaseAdmin = false;
    }
  }

  res.status(200).json({
    ok: true,
    env: {
      midtransKey,
      firebaseAdmin,
    },
  });
});

// Wrapper untuk menangani async route handler secara aman
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Routes Pembayaran
app.post('/api/create-transaction', asyncHandler(handleCreateTransaction));
app.post('/api/midtrans-webhook', asyncHandler(handleWebhook));
app.post('/api/check-payment', asyncHandler(handleCheckPayment));

// Error handling middleware terpusat (tidak membocorkan stack trace / rahasia)
app.use((err, req, res, next) => {
  const statusCode = err.status || 500;
  const message = err.message || 'Terjadi kesalahan pada server pembayaran.';
  console.error(`[Error] ${req.method} ${req.url} (${statusCode}):`, message);

  res.status(statusCode).json({
    error: message,
    timestamp: new Date().toISOString(),
  });
});

module.exports = app;
