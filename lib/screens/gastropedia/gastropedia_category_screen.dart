import 'package:flutter/material.dart';
import '../../models/gastropedia_item_model.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gastropedia/gastropedia_header.dart';
import '../../routes/app_routes.dart';

class GastropediaCategoryScreen extends StatelessWidget {
  final GastropediaCategory category;

  const GastropediaCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final items = GastropediaData.getByCategory(category);

    return AppScaffold(
      body: Column(
        children: [
          const SizedBox(height: 6),

          // 1. Header Top Bar
          GastropediaHeader(title: category.label),

          const SizedBox(height: 10),

          // 2. Grid 2 Kolom (Card List)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.gastropediaDetail,
                      arguments: item,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2F7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFC7DCED),
                        width: 1.4,
                      ),
                      boxShadow: [
                        // Shadow utama — depth card
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        // Shadow bawah lebih lembut
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Foto Lingkaran Makanan/Buah/Sayur (Circular Plate)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 8),
                            child: Center(
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    // Shadow utama lingkaran
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                    // Highlight cahaya atas (efek emboss)
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  item.imageAsset,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, _, _) => Container(
                                    color: const Color(0xFF639BC6),
                                    child: const Icon(
                                      Icons.restaurant_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bar Putih di Bawah (Label Nama Makanan)
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFDAECF5),
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 8,
                          ),
                          child: Text(
                            item.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E5D7D),
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
