/**
 * SatuSehat Service Facade
 * Menggabungkan modul auth (OAuth 2.0) dan patient (HL7 FHIR Resource)
 * untuk melayani rute backend Express.js dan aplikasi mobile.
 */

const auth = require('./auth');
const patient = require('./patient');

class SatuSehatService {
  constructor() {
    this.auth = auth;
    this.patient = patient;
  }

  isConfigured() {
    return auth.isConfigured();
  }

  async getAccessToken() {
    return auth.getToken();
  }

  async getPatientByNik(nik) {
    const result = await patient.getByNik(nik);
    if (!result.ok) {
      console.error('[SatuSehat Patient Search Error]', result.data);
      const errMsg = result.data?.issue?.[0]?.diagnostics || result.data?.message || 'Gagal mencari data pasien di SatuSehat';
      throw new Error(errMsg);
    }

    const data = result.data;
    if (!data || data.total === 0 || !Array.isArray(data.entry) || data.entry.length === 0) {
      return null;
    }

    const fhirPatient = data.entry[0].resource;
    return patient.formatPatient(fhirPatient);
  }

  async getPatientByIhsNumber(ihsNumber) {
    const result = await patient.getById(ihsNumber);
    if (!result.ok) {
      console.error('[SatuSehat Patient By IHS Error]', result.data);
      const errMsg = result.data?.issue?.[0]?.diagnostics || result.data?.message || 'Gagal memuat data IHS pasien';
      throw new Error(errMsg);
    }
    return patient.formatPatient(result.data);
  }

  async getRawPatientByNik(nik) {
    return patient.getByNik(nik);
  }

  async getRawPatientByIhs(ihsNumber) {
    return patient.getById(ihsNumber);
  }

  async postPatient(patientPayload) {
    return patient.create(patientPayload);
  }

  async patchPatient(ihsNumber, patchOperations) {
    return patient.patch(ihsNumber, patchOperations);
  }

  formatPatientData(fhir) {
    return patient.formatPatient(fhir);
  }
}

module.exports = new SatuSehatService();
