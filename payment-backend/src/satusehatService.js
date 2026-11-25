/**
 * SatuSehat FHIR Service (Kemenkes RI)
 * Menangani integrasi autentikasi OAuth 2.0 dan pertukaran resource FHIR R4
 * khususnya resource Patient.
 */

class SatuSehatService {
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

  /**
   * Cek apakah kredensial SatuSehat sudah dikonfigurasi di environment
   */
  isConfigured() {
    return (
      Boolean(this.clientId) &&
      Boolean(this.clientSecret) &&
      !this.clientId.includes('YOUR_') &&
      !this.clientSecret.includes('YOUR_')
    );
  }

  /**
   * Mendapatkan OAuth 2.0 Access Token dari SatuSehat DTO Kemenkes
   */
  async getAccessToken() {
    if (!this.isConfigured()) {
      throw new Error(
        'Kredensial SatuSehat (SATUSEHAT_CLIENT_ID & SATUSEHAT_CLIENT_SECRET) belum dikonfigurasi di environment backend.'
      );
    }

    const now = Date.now();
    // Gunakan cached token jika masih valid (diberi buffer 60 detik)
    if (this.cachedToken && this.tokenExpiresAt && now < this.tokenExpiresAt - 60000) {
      return this.cachedToken;
    }

    try {
      // Endpoint otentikasi SatuSehat DTO mewajibkan parameter grant_type=client_credentials
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
      // expires_in dalam satuan detik (default 3600 = 1 jam)
      const expiresInMs = (parseInt(data.expires_in, 10) || 3600) * 1000;
      this.tokenExpiresAt = now + expiresInMs;

      return this.cachedToken;
    } catch (err) {
      console.error('[SatuSehat] Gagal mendapatkan access token:', err.message);
      throw err;
    }
  }

  /**
   * Mencari resource Patient berdasarkan NIK KTP (16 digit)
   * Menggunakan format query FHIR: Patient?identifier=https://fhir.kemkes.go.id/id/nik|{nik}
   */
  async getPatientByNik(nik) {
    const cleanNik = String(nik || '').trim();
    if (!/^\d{16}$/.test(cleanNik)) {
      throw new Error('Nomor Induk Kependudukan (NIK) harus berupa 16 digit angka valid.');
    }

    const token = await this.getAccessToken();
    const queryUrl = `${this.baseUrl}/fhir-r4/v1/Patient?identifier=https://fhir.kemkes.go.id/id/nik|${encodeURIComponent(cleanNik)}`;

    try {
      const res = await fetch(queryUrl, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/json',
        },
      });

      const data = await res.json();

      if (!res.ok) {
        console.error('[SatuSehat Patient Search Error]', data);
        const errMsg = data?.issue?.[0]?.diagnostics || data?.message || 'Gagal mencari data pasien di SatuSehat';
        throw new Error(errMsg);
      }

      // FHIR mengembalikan response tipe Bundle
      if (!data || data.total === 0 || !Array.isArray(data.entry) || data.entry.length === 0) {
        return null; // Pasien tidak ditemukan di data SatuSehat
      }

      const fhirPatient = data.entry[0].resource;
      return this.formatPatientData(fhirPatient);
    } catch (err) {
      console.error('[SatuSehat] Query Patient by NIK error:', err.message);
      throw err;
    }
  }

  /**
   * Mengambil resource Patient berdasarkan IHS Number langsung
   * Endpoint: Patient/{ihsNumber}
   */
  async getPatientByIhsNumber(ihsNumber) {
    const cleanIhs = String(ihsNumber || '').trim();
    if (!cleanIhs) {
      throw new Error('IHS Number pasien tidak boleh kosong.');
    }

    const token = await this.getAccessToken();
    const queryUrl = `${this.baseUrl}/fhir-r4/v1/Patient/${encodeURIComponent(cleanIhs)}`;

    try {
      const res = await fetch(queryUrl, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/json',
        },
      });

      const data = await res.json();

      if (!res.ok) {
        console.error('[SatuSehat Patient By IHS Error]', data);
        const errMsg = data?.issue?.[0]?.diagnostics || data?.message || 'Gagal memuat data IHS pasien';
        throw new Error(errMsg);
      }

      return this.formatPatientData(data);
    } catch (err) {
      console.error('[SatuSehat] Query Patient by IHS error:', err.message);
      throw err;
    }
  }

  /**
   * Mengambil raw FHIR bundle Patient berdasarkan NIK
   */
  async getRawPatientByNik(nik) {
    const cleanNik = String(nik || '').trim();
    const token = await this.getAccessToken();
    const queryUrl = `${this.baseUrl}/fhir-r4/v1/Patient?identifier=https://fhir.kemkes.go.id/id/nik|${encodeURIComponent(cleanNik)}`;
    const res = await fetch(queryUrl, {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
    });
    const data = await res.json();
    return { status: res.status, ok: res.ok, data };
  }

  /**
   * Mengambil raw FHIR Patient berdasarkan IHS Number
   */
  async getRawPatientByIhs(ihsNumber) {
    const cleanIhs = String(ihsNumber || '').trim();
    const token = await this.getAccessToken();
    const queryUrl = `${this.baseUrl}/fhir-r4/v1/Patient/${encodeURIComponent(cleanIhs)}`;
    const res = await fetch(queryUrl, {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
    });
    const data = await res.json();
    return { status: res.status, ok: res.ok, data };
  }

  /**
   * Mengunggah Resource Patient baru (FHIR POST)
   * Berguna untuk upload data pasien / audit trail jika ada kesalahan NIK
   */
  async postPatient(patientPayload) {
    const token = await this.getAccessToken();
    const postUrl = `${this.baseUrl}/fhir-r4/v1/Patient`;

    const res = await fetch(postUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(patientPayload),
    });

    const data = await res.json();
    return {
      status: res.status,
      ok: res.ok,
      data,
    };
  }

  /**
   * Memperbarui Resource Patient (FHIR PATCH)
   * Format payload berupa JSON Patch RFC 6902
   */
  async patchPatient(ihsNumber, patchOperations) {
    const token = await this.getAccessToken();
    const patchUrl = `${this.baseUrl}/fhir-r4/v1/Patient/${encodeURIComponent(ihsNumber)}`;

    const res = await fetch(patchUrl, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json-patch+json',
        Accept: 'application/json',
      },
      body: JSON.stringify(patchOperations),
    });

    const data = await res.json();
    return {
      status: res.status,
      ok: res.ok,
      data,
    };
  }

  /**
   * Helper normalisasi resource FHIR Patient ke representasi objek JSON yang bersih
   */
  formatPatientData(fhir) {
    if (!fhir) return null;

    let nik = null;
    let ihsNumber = fhir.id || null;

    if (Array.isArray(fhir.identifier)) {
      for (const idObj of fhir.identifier) {
        if (idObj.system === 'https://fhir.kemkes.go.id/id/nik') {
          nik = idObj.value;
        } else if (idObj.system === 'https://fhir.kemkes.go.id/id/ihs-number') {
          ihsNumber = idObj.value;
        }
      }
    }

    // Ekstrak nama resmi
    let name = '';
    if (Array.isArray(fhir.name) && fhir.name.length > 0) {
      const nameObj = fhir.name[0];
      name = nameObj.text || (nameObj.given ? nameObj.given.join(' ') : '') || '';
    }

    // Normalisasi jenis kelamin
    let gender = 'Lainnya';
    if (fhir.gender === 'male') {
      gender = 'Laki-laki';
    } else if (fhir.gender === 'female') {
      gender = 'Perempuan';
    }

    // Tanggal lahir (format FHIR: YYYY-MM-DD)
    const birthDate = fhir.birthDate || null;

    // Alamat
    let address = '';
    if (Array.isArray(fhir.address) && fhir.address.length > 0) {
      const addr = fhir.address[0];
      const line = Array.isArray(addr.line) ? addr.line.join(', ') : '';
      const city = addr.city || '';
      address = [line, city].filter(Boolean).join(', ');
    }

    // Kontak/telepon jika ada
    let phone = null;
    if (Array.isArray(fhir.telecom)) {
      const phoneItem = fhir.telecom.find((t) => t.system === 'phone');
      if (phoneItem) phone = phoneItem.value;
    }

    return {
      resourceType: 'Patient',
      ihsNumber,
      nik,
      name,
      gender,
      birthDate,
      address,
      phone,
      active: fhir.active ?? true,
    };
  }
}

module.exports = new SatuSehatService();
