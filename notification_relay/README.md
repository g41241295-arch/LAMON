# LAMON Notification Relay (Vercel Serverless Function)

Serverless HTTP relay untuk mengirim notifikasi push chat FCM ke Android di luar aplikasi tanpa Firebase Blaze (berjalan di paket Spark gratis + Vercel Hobby gratis).

---

## 🔒 Privasi & Keamanan
- Menggunakan verifikasi Firebase ID Token (`Bearer <token>`).
- Isi pesan chat **TIDAK PERNAH** dikirim ke relay dan tidak pernah tampil di notifikasi push.
- Judul notifikasi adalah nama lawan bicara, isi generik `"Pesan baru"`.
- Kunci Service Account **HANYA** disimpan di environment variable Vercel Dashboard (`FIREBASE_SERVICE_ACCOUNT`).

---

## 🚀 Panduan Deploy ke Vercel (Gratis)

### 1. Dapatkan Service Account Key dari Firebase Console
1. Buka [Firebase Console](https://console.firebase.google.com/).
2. Pilih project **LAMON**.
3. Klik ikon gear ⚙️ (**Project settings**) > tab **Service accounts**.
4. Klik tombol **Generate new private key** > konfirmasi **Generate key**.
5. File JSON akan terunduh ke komputer Anda.
6. Buka file JSON tersebut dengan text editor (mis. Notepad), lalu salin seluruh isi teksnya (mulai dari `{` sampai `}`).

### 2. Deploy ke Vercel via Dashboard (Tanpa CLI)
1. Push commit repo ini ke GitHub / GitLab.
2. Buka dashboard [Vercel](https://vercel.com/) dan login (akun Hobby gratis).
3. Klik **Add New...** > **Project**.
4. Import repository **PBM SEMESTER 5**.
5. Pada bagian **Root Directory**, klik **Edit** dan pilih folder:
   ```
   notification_relay
   ```
   *(PENTING: Jangan biarkan root directory di tingkat utama repo, pastikan diset ke `notification_relay`)*.
6. Di bagian **Environment Variables**, tambahkan:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: *(tempel teks JSON service account yang telah Anda salin tadi)*
7. Klik **Deploy**.
8. Setelah deployment berhasil, Vercel akan memberikan domain URL publik, contohnya:
   ```
   https://lamon-notification-relay.vercel.app
   ```

### 3. Konfigurasi di Flutter App
1. Buka file [`lib/config/notification_config.dart`](file:///c:/laragon/www/PBM%20SEMESTER%205/lib/config/notification_config.dart).
2. Masukkan URL endpoint relay Anda:
   ```dart
   static const String relayEndpoint = 'https://lamon-notification-relay.vercel.app/api/notify';
   ```
3. Selesai! Aplikasi Flutter akan otomatis memicu relay setiap kali pesan berhasil terkirim.
