const app = require('./src/app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`[LAMON Payment Backend] Server berjalan di http://localhost:${PORT}`);
  console.log(`[Mode] Midtrans Sandbox (isProduction: false)`);
});
