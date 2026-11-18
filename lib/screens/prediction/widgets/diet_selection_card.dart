import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card pilihan jenis diet pola makan (Omnivora, Vegetarian, Vegan)
class DietSelectionCard extends StatelessWidget {
  final String selectedDiet;
  final ValueChanged<String> onSelected;

  const DietSelectionCard({
    super.key,
    required this.selectedDiet,
    required this.onSelected,
  });

  static const List<Map<String, dynamic>> diets = [
    {
      'id': 'Omnivora',
      'title': 'Omnivora',
      'subtitle': 'Semua jenis',
      'icon': 'assets/images/omnivora.png',
      'fallbackIcon': Icons.restaurant_rounded,
    },
    {
      'id': 'Vegetarian',
      'title': 'Vegetarian',
      'subtitle': 'Tanpa daging',
      'icon': 'assets/images/vegetarian.png',
      'fallbackIcon': Icons.eco_rounded,
    },
    {
      'id': 'Vegan',
      'title': 'Vegan',
      'subtitle': 'Bahan nabati',
      'icon': 'assets/images/vegan.png',
      'fallbackIcon': Icons.spa_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4E68).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEBE3D0),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 18,
                  color: Color(0xFF1C4E68),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pola Konsumsi Utama',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C4E68),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pilih kategori diet yang sesuai dengan kebiasaanmu',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B8797),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── 3 Pilihan Horizontal ───
          Row(
            children: diets.map((diet) {
              final id = diet['id'] as String;
              final isSelected = selectedDiet.toLowerCase() == id.toLowerCase();
              final iconPath = diet['icon'] as String;
              final fallbackIcon = diet['fallbackIcon'] as IconData;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => onSelected(id),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF0F6F9)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF276F8F)
                              : const Color(0xFFEBE3D0),
                          width: isSelected ? 1.8 : 1.2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFF276F8F).withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon bulat
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF276F8F)
                                  : const Color(0xFFF7F5EE),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF276F8F)
                                    : const Color(0xFFEBE3D0),
                                width: 1.0,
                              ),
                            ),
                            child: Image.asset(
                              iconPath,
                              width: 22,
                              height: 22,
                              color: isSelected ? Colors.white : null,
                              errorBuilder: (_, __, ___) => Icon(
                                fallbackIcon,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1C4E68),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Judul
                          Text(
                            diet['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: isSelected
                                  ? const Color(0xFF1C4E68)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Subjudul
                          Text(
                            diet['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF276F8F)
                                  : const Color(0xFF6B8797),
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
