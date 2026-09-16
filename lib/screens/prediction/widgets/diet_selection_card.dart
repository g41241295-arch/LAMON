import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

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
      'icon': Icons.restaurant_rounded,
    },
    {
      'id': 'Vegetarian',
      'title': 'Vegetarian',
      'subtitle': 'Tanpa daging',
      'icon': Icons.spa_rounded,
    },
    {
      'id': 'Vegan',
      'title': 'Vegan',
      'subtitle': 'Tanpa hewani',
      'icon': Icons.eco_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.restaurant_menu_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Jenis Pola Makan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Pilih jenis diet yang paling sesuai dengan keseharianmu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.brownSubtext,
            ),
          ),
          const SizedBox(height: 14),

          // 3 Kartu Sejajar Horizontal
          Row(
            children: diets.map((diet) {
              final id = diet['id'] as String;
              final isSelected = selectedDiet.toLowerCase() == id.toLowerCase();

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
                            ? const Color(0xFFDCEDF7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.16),
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFF0F5F8),
                            ),
                            child: Icon(
                              diet['icon'] as IconData,
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Judul
                          Text(
                            diet['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Subjudul
                          Text(
                            diet['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF3A6E88)
                                  : const Color(0xFF7A8F9B),
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
