import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../widgets/gastropedia/gastropedia_accordion.dart';

class GastropediaDetailScreen extends StatelessWidget {
  final GastropediaItem item;

  const GastropediaDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // 1. Header Top Bar
            GastropediaHeader(title: item.name),

            const SizedBox(height: 14),

            // 2. Banner Foto Utama Item
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF639BC6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gambar Utama
                    SizedBox(
                      height: 170,
                      child: Image.asset(
                        item.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFEBF3F8),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            size: 48,
                            color: Color(0xFF639BC6),
                          ),
                        ),
                      ),
                    ),

                    // Bar Putih di Bawah Gambar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      child: Text(
                        item.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E5D7D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Tiga Accordion Independen (Deskripsi, Manfaat, Kandungan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Accordion 1: Deskripsi
                  GastropediaAccordion(
                    title: 'Deskripsi',
                    initialExpanded: false,
                    content: Text(
                      item.deskripsi,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: Color(0xFF2C495E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Accordion 2: Manfaat
                  GastropediaAccordion(
                    title: 'Manfaat',
                    initialExpanded: false,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.manfaat.map((text) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            text,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: Color(0xFF2C495E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Accordion 3: Kandungan
                  GastropediaAccordion(
                    title: 'Kandungan Gizi',
                    initialExpanded: false,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.kandungan.map((text) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            text,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: Color(0xFF2C495E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
