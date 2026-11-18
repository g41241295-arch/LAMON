import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_scaffold.dart';

class DiseasePredictionIntroScreen extends StatelessWidget {
  const DiseasePredictionIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFCFBF7),
          Color(0xFFF7F4EB),
          Color(0xFFF2EEDB),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── 1. Header (Back Button, Yellow Title Pill, Riwayat Button) ───
            _buildHeader(context),

            // ─── 2. Scrollable Intro Content ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Hero Utama
                    _buildMainIntroCard(),
                    const SizedBox(height: 20),

                    // Section Title: Alur Pemeriksaan
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Tahapan Pemeriksaan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C4E68),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3 Card Langkah Tersusun Vertikal
                    _buildStepCard(
                      stepNumber: '01',
                      title: 'Pola Makan Sehari-hari',
                      subtitle:
                          'Frekuensi konsumsi buah, sayur, masakan rumah, dan hidrasi air putih.',
                      icon: Icons.restaurant_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildStepCard(
                      stepNumber: '02',
                      title: 'Identifikasi Makanan Berisiko',
                      subtitle:
                          'Frekuensi konsumsi daging berlemak, camilan asin, dan makanan olahan.',
                      icon: Icons.fastfood_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildStepCard(
                      stepNumber: '03',
                      title: 'Gaya Hidup & Produk Turunan',
                      subtitle:
                          'Konsumsi produk susu/keju, minuman beralkohol, dan kebiasaan santap.',
                      icon: Icons.nightlife_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Medical Notice / Disclaimer Card
                    _buildMedicalNoticeCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ─── 3. Bottom CTA Button ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF276F8F),
                        Color(0xFF1C4E68),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1C4E68).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/prediksi-penyakit/form');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mulai Pemeriksaan',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header gaya Catat Makanan: Back circle, Yellow Title pill, History circle
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tombol Kembali (Kiri)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1C4E68),
                  size: 20,
                ),
              ),
            ),
          ),

          // Pill Judul Kuning (Tengah, gaya Catat Makanan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7D6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE8D7A5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Prediksi Penyakit',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C4E68),
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Tombol Riwayat (Kanan)
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () =>
                  Navigator.pushNamed(context, '/prediksi-penyakit/riwayat'),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF1C4E68),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card Hero Utama yang profesional, bersih, dan klinis
  Widget _buildMainIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4E68).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Medis Klinis Modern (Tanpa Maskot Kartun)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F3F7),
                  Color(0xFFD6EBF2),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFBCE0EC),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF276F8F).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              size: 36,
              color: Color(0xFF276F8F),
            ),
          ),
          const SizedBox(height: 16),

          // Judul Utama
          Text(
            'Analisis Risiko Asam Lambung',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C4E68),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Paragraf Deskripsi Klinis & Informatif
          Text(
            'Evaluasi potensi risiko refluks asam lambung dan GERD berbasis analisis data kebiasaan makan serta gaya hidup harianmu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B8797),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Baris Tag Indikator
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureTag(Icons.bolt_rounded, 'Cepat (~2 Menit)'),
              _buildFeatureTag(Icons.analytics_outlined, '10 Indikator'),
              _buildFeatureTag(Icons.lock_outline_rounded, 'Data Aman & Privat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF276F8F)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C4E68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4E68).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Nomor Langkah
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4E5EE),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF276F8F),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Judul & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C4E68),
                        ),
                      ),
                    ),
                    Icon(icon, size: 16, color: const Color(0xFF9CB3C2)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B8797),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFD97706),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Skrining ini dirancang sebagai panduan preventif mandiri berbasis kebiasaan makan dan tidak menggantikan diagnosis klinis dokter spesialis.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
