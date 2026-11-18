# Panduan Backend Pembayaran Midtrans Snap (Sandbox) - Aplikasi LAMON

Layanan backend ini bertindak sebagai jembatan independen (Node.js LTS) antara aplikasi Flutter LAMON dan Midtrans Payment Gateway (Snap API Sandbox) dengan menggunakan Firebase Admin SDK untuk membaca dan memperbarui data transaksi di Firestore secara aman dan idempoten.

---

## 1. Persiapan Kredensial & Lingkungan

### a. Membuat Service Account Firebase Admin SDK
1. Buka [Firebase Console](https://console.firebase.google.com/).
2. Masuk ke proyek LAMON Anda.
3. Klik ikon gerigi (Settings) di kiri atas $\rightarrow$ **Project settings**.
4. Buka tab **Service accounts**.
5. Klik tombol **Generate new private key**, lalu konfirmasi dengan **Generate key**.
6. Sebuah berkas JSON (misalnya `lamon-xxxx-firebase-adminsdk-xxxx.json`) akan diunduh ke komputer Anda.
7. **PENTING: JANGAN PERNAH** memasukkan atau melakukan commit file JSON ini ke git repo!
8. Untuk digunakan pada environment variable, ubah isi file JSON tersebut menjadi string **Base64**:
   - **Di PowerShell (Windows):**
     ```powershell
     [Convert]::ToBase64String([IO.File]::ReadAllBytes("path\ke\file-service-account.json")) | Set-Clipboard
     ```
     *(Hasil Base64 langsung tersalin di clipboard Anda)*
   - **Di Linux/macOS:**
     ```bash
     base64 -w 0 path/ke/file-service-account.json | pbcopy # atau xclip
     ```
9. Tempelkan nilai Base64 tersebut ke variabel lingkungan `FIREBASE_SERVICE_ACCOUNT`.

### b. Mengambil Server Key Midtrans Sandbox
1. Masuk ke [Midtrans Dashboard](https://dashboard.midtrans.com/) (pastikan berada di mode **Sandbox**).
2. Di menu navigasi samping, klik **Settings** $\rightarrow$ **Access Keys**.
3. Salin **Server Key** (berawalan `SB-Mid-server-...`) $\rightarrow$ masukkan ke variabel `MIDTRANS_SERVER_KEY`.
4. Salin **Client Key** (berawalan `SB-Mid-client-...`) $\rightarrow$ masukkan ke variabel `MIDTRANS_CLIENT_KEY`.
5. Pastikan `MIDTRANS_IS_PRODUCTION=false`.

---

## 2. Menjalankan Backend Secara Lokal

1. Masuk ke folder `payment-backend`:
   ```bash
   cd payment-backend
   npm install
   ```
2. Buat berkas `.env` dari `.env.example`:
   ```bash
   cp .env.example .env
   ```
3. Buka berkas `.env` dan isi nilai rahasia Anda:
   ```env
   MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxxx
   MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxxxxxx
   MIDTRANS_IS_PRODUCTION=false
   FIREBASE_SERVICE_ACCOUNT=eyJuYW1lIjoicGxhY2Vob2xkZXIi...
   PORT=3000
   ```
4. Jalankan server lokal:
   ```bash
   npm start
   ```
   Server akan aktif di `http://localhost:3000`.

---

## 3. Menguji Webhook Saat Pengembangan Lokal Menggunakan Tunnel

Karena Midtrans berjalan di cloud dan perlu mengirimkan notifikasi HTTP POST ke server Anda, gunakan tunneling tools seperti **ngrok** atau **localtunnel**:

1. Jalankan ngrok:
   ```bash
   npx ngrok http 3000
   ```
   atau
   ```bash
   npx localtunnel --port 3000
   ```
2. Anda akan mendapatkan URL publik HTTPS, contoh: `https://abcd-1234.ngrok-free.app`.
3. Buka Midtrans Dashboard Sandbox $\rightarrow$ **Settings** $\rightarrow$ **Configuration**.
4. Isi **Payment Notification URL** dengan:
   ```
   https://abcd-1234.ngrok-free.app/api/midtrans-webhook
   ```
5. Simpan pengaturan. Kini webhook pembayaran sandbox akan otomatis masuk ke backend lokal Anda.

---

## 4. Deploy Backend ke Vercel (Rekomendasi Utama)

Backend ini dirancang kompatibel penuh dengan serverless Vercel:

1. Buat akun di [Vercel](https://vercel.com/) jika belum punya.
2. Pasang Vercel CLI (atau hubungkan repository GitHub):
   ```bash
   npm i -g vercel
   ```
3. Di dalam folder `payment-backend`, jalankan perintah:
   ```bash
   vercel
   ```
4. Ikuti instruksi setup proyek.
5. Masuk ke Dashboard Vercel $\rightarrow$ Proyek Anda $\rightarrow$ **Settings** $\rightarrow$ **Environment Variables**, lalu tambahkan:
   - `MIDTRANS_SERVER_KEY`: (Server Key Sandbox Anda)
   - `MIDTRANS_CLIENT_KEY`: (Client Key Sandbox Anda)
   - `MIDTRANS_IS_PRODUCTION`: `false`
   - `FIREBASE_SERVICE_ACCOUNT`: (String Base64 service account JSON Anda)
6. Lakukan deploy production:
   ```bash
   vercel --prod
   ```
7. Anda akan mendapatkan domain permanen, misalnya `https://lamon-payment.vercel.app`.
8. Di Midtrans Dashboard Sandbox $\rightarrow$ **Settings** $\rightarrow$ **Configuration**, masukkan **Payment Notification URL**:
   ```
   https://lamon-payment.vercel.app/api/midtrans-webhook
   ```

---

## 5. Deploy Alternatif: Render (Web Service Node.js)

1. Buka [Render](https://render.com/).
2. Buat **New Web Service** dan hubungkan repo GitHub Anda (atau gunakan Public Git Repository).
3. Root Directory: `payment-backend`
4. Runtime: `Node`
5. Build Command: `npm install`
6. Start Command: `npm start`
7. Tambahkan Environment Variables:
   - `MIDTRANS_SERVER_KEY`
   - `MIDTRANS_CLIENT_KEY`
   - `MIDTRANS_IS_PRODUCTION=false`
   - `FIREBASE_SERVICE_ACCOUNT`
8. Setelah aktif, isi Notification URL di Midtrans dengan URL Render Anda:
   `https://<nama-app>.onrender.com/api/midtrans-webhook`

---

## 6. Menghubungkan Backend ke Aplikasi Flutter

Alamat backend tidak bersifat rahasia dan dapat dikonfigurasi melalui `--dart-define` saat build, atau langsung disetel pada `lib/constants/payment_config.dart`:

- **Saat Menjalankan Flutter:**
  - Jika menguji di Emulator Android lokal (merujuk ke `localhost:3000` di laptop):
    Gunakan alamat default `http://10.0.2.2:3000`.
  - Jika backend sudah di-deploy ke Vercel:
    ```bash
    flutter run --dart-define=PAYMENT_BACKEND_URL=https://lamon-payment.vercel.app
    ```
  - Untuk build APK rilis:
    ```bash
    flutter build apk --release --dart-define=PAYMENT_BACKEND_URL=https://lamon-payment.vercel.app
    ```

---

## 7. Prosedur Rotasi Key Jika Kredensial Sempat Bocor

Jika Server Key Midtrans atau Service Account Firebase pernah tidak sengaja terekspos:
1. **Midtrans Server Key**:
   - Buka Midtrans Dashboard $\rightarrow$ **Settings** $\rightarrow$ **Access Keys**.
   - Klik **Generate New Key** (atau minta reset Server Key).
   - Segera perbarui environment variable `MIDTRANS_SERVER_KEY` di hosting backend (Vercel/Render).
2. **Firebase Service Account**:
   - Buka [Google Cloud Console](https://console.cloud.google.com/) $\rightarrow$ **IAM & Admin** $\rightarrow$ **Service Accounts**.
   - Temukan service account terkait $\rightarrow$ tab **Keys**.
   - Hapus key yang bocor.
   - Buat key baru, encode ke Base64, dan perbarui di Vercel/Render.
