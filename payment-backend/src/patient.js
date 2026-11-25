/**
 * SatuSehat HL7 FHIR Patient Resource Module (Kemenkes RI)
 * Menangani operasi GET, POST, dan PATCH untuk resource Patient
 */

const auth = require('./auth');

class PatientResource {
  constructor() {
    this.baseUrl = (
      process.env.SATUSEHAT_BASE_URL ||
      'https://api-satusehat-stg.dto.kemkes.go.id'
    ).trim().replace(/\/+$/, '');
  }

  /**
   * 1. [GET] Mencari resource FHIR Patient berdasarkan NIK KTP (16 digit)
   */
  async getByNik(nik) {
    const cleanNik = String(nik || '').trim();
    if (!/^\d{16}$/.test(cleanNik)) {
      throw new Error('NIK harus berupa 16 digit angka valid.');
    }

    const token = await auth.getToken();
    const queryUrl = `${this.baseUrl}/fhir-r4/v1/Patient?identifier=https://fhir.kemkes.go.id/id/nik|${encodeURIComponent(cleanNik)}`;

    const res = await fetch(queryUrl, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/json',
      },
    });

    const data = await res.json();
    return {
      status: res.status,
      ok: res.ok,
      data,
    };
  }

  /**
   * 2. [GET] Mengambil resource FHIR Patient berdasarkan Nomor IHS
   */
  async getById(ihsNumber) {
    const cleanIhs = String(ihsNumber || '').trim();
    if (!cleanIhs) {
      throw new Error('Nomor IHS tidak boleh kosong.');
    }

    const token = await auth.getToken();
    const queryUrl = `${this.baseUrl}/fhir-r4/v1/Patient/${encodeURIComponent(cleanIhs)}`;

    const res = await fetch(queryUrl, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/json',
      },
    });

    const data = await res.json();
    return {
      status: res.status,
      ok: res.ok,
      data,
    };
  }

  /**
   * 3. [POST] Mengunggah Resource Patient Baru ke SatuSehat
   * Bisa digunakan untuk mendaftarkan pasien atau mendemokan audit trail respon Kemenkes
   */
  async create(patientPayload) {
    const token = await auth.getToken();
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
   * 4. [PATCH] Memperbarui elemen Resource Patient di SatuSehat
   * Menggunakan format standar JSON Patch RFC 6902
   */
  async patch(ihsNumber, patchOperations) {
    const token = await auth.getToken();
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
   * Helper normalisasi resource FHIR Patient ke format objek ringkas
   */
  formatPatient(fhir) {
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

    let name = '';
    if (Array.isArray(fhir.name) && fhir.name.length > 0) {
      const nameObj = fhir.name[0];
      name = nameObj.text || (nameObj.given ? nameObj.given.join(' ') : '') || '';
    }

    let gender = 'Lainnya';
    if (fhir.gender === 'male') {
      gender = 'Laki-laki';
    } else if (fhir.gender === 'female') {
      gender = 'Perempuan';
    }

    const birthDate = fhir.birthDate || null;

    let address = '';
    if (Array.isArray(fhir.address) && fhir.address.length > 0) {
      const addr = fhir.address[0];
      const line = Array.isArray(addr.line) ? addr.line.join(', ') : '';
      const city = addr.city || '';
      address = [line, city].filter(Boolean).join(', ');
    }

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

module.exports = new PatientResource();
