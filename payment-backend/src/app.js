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
