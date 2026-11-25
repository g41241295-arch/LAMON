/**
 * SatuSehat Auth Module (Kemenkes RI)
 * Mengelola perolehan dan perpanjangan Access Token OAuth 2.0 (berlaku 60 menit)
 */

class SatuSehatAuth {
  constructor() {
    this.baseUrl = (
      process.env.SATUSEHAT_BASE_URL ||
      'https://api-satusehat-stg.dto.kemkes.go.id'
    ).trim().replace(/\/+$/, '');

    this.clientId = (process.env.SATUSEHAT_CLIENT_ID || '').trim();
    this.clientSecret = (process.env.SATUSEHAT_CLIENT_SECRET || '').trim();
    this.orgId = (process.env.SATUSEHAT_ORG_ID || '').trim();

    this.cachedToken = null;
    this.tokenExpiresAt = null;
  }

  isConfigured() {
    return (
      Boolean(this.clientId) &&
      Boolean(this.clientSecret) &&
      !this.clientId.includes('YOUR_') &&
      !this.clientSecret.includes('YOUR_')
    );
  }

  /**
   * Mengambil atau menyegarkan Access Token OAuth 2.0
   * Token disimpan dalam cache memori selama masa berlakunya (60 menit)
   */
  async getToken() {
    if (!this.isConfigured()) {
      throw new Error(
        'Kredensial SatuSehat (SATUSEHAT_CLIENT_ID & SATUSEHAT_CLIENT_SECRET) belum dikonfigurasi di file .env backend.'
      );
    }

    const now = Date.now();
    // Gunakan cached token jika masih aktif (diberi buffer 60 detik)
    if (this.cachedToken && this.tokenExpiresAt && now < this.tokenExpiresAt - 60000) {
      return this.cachedToken;
    }

    try {
      const authUrl = `${this.baseUrl}/oauth2/v1/accesstoken?grant_type=client_credentials`;
      const formParams = new URLSearchParams();
      formParams.append('client_id', this.clientId);
      formParams.append('client_secret', this.clientSecret);
      formParams.append('grant_type', 'client_credentials');

      const res = await fetch(authUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formParams.toString(),
      });

      const data = await res.json();

      if (!res.ok) {
        const errorDetail =
          data?.message ||
          data?.error_description ||
          data?.fault?.faultstring ||
          (typeof data === 'string' ? data : JSON.stringify(data)) ||
          res.statusText;
        console.error('[SatuSehat Auth Error]', data);
        throw new Error(`Autentikasi SatuSehat gagal (${res.status}): ${errorDetail}`);
      }

      this.cachedToken = data.access_token;
      // expires_in dalam satuan detik (default 3600 = 1 jam / 60 menit)
      const expiresInMs = (parseInt(data.expires_in, 10) || 3600) * 1000;
      this.tokenExpiresAt = now + expiresInMs;

      return this.cachedToken;
    } catch (err) {
      console.error('[SatuSehat Auth] Gagal meminta token:', err.message);
      throw err;
    }
  }

  /**
   * Detail masa aktif token saat ini
   */
  getTokenInfo() {
    const now = Date.now();
    const remainingSeconds = this.tokenExpiresAt ? Math.max(0, Math.floor((this.tokenExpiresAt - now) / 1000)) : 0;
    return {
      hasActiveToken: Boolean(this.cachedToken && remainingSeconds > 0),
      remainingSeconds,
      remainingMinutes: Math.floor(remainingSeconds / 60),
    };
  }
}

module.exports = new SatuSehatAuth();
