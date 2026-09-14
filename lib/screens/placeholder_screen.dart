import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/primary_button.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String? description;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primaryText,
                          size: 22,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text(
                  'LAMON',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 60), // Balance width
              ],
            ),

            const Spacer(),

            // Mascot with Glow
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFE566).withValues(alpha: 0.6),
                          blurRadius: 36,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    AppAssets.logo,
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1B8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDEC99B),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Color(0xFF7A4426),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tahap Pengembangan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A4426),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryText,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                description ??
                    'Fitur ini sedang dalam proses pengembangan oleh tim Anda sesuai alur kebutuhan berikutnya.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF5A7B8E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Back button
            PrimaryButton(
              text: 'Kembali ke Beranda',
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/beranda',
                  (route) => false,
                );
              },
            ),

            const Spacer(),

            // Footer
            const Text(
              'Aplikasi LAMON • Pemantauan Kesehatan Lambung',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C9EA8),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
