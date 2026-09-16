import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// Progress stepper 3 langkah (1-2-3) dengan garis horizontal
/// - Selesai: lingkaran teal berisi centang putih
/// - Aktif: outline teal berisi nomor langkah
/// - Belum: lingkaran abu-abu kosong dengan nomor redup
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1, 2, atau 3
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 1; i <= totalSteps; i++) ...[
            _buildStepNode(stepNumber: i),
            if (i < totalSteps)
              Expanded(
                child: Container(
                  height: 2.5,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i < currentStep
                        ? AppColors.primary
                        : const Color(0xFFD6E2E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepNode({required int stepNumber}) {
    final isCompleted = stepNumber < currentStep;
    final isActive = stepNumber == currentStep;

    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33276F8F),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.check,
          size: 18,
          color: Colors.white,
        ),
      );
    }

    if (isActive) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepNumber',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );
    }

    // Step belum tercapai
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F7),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD1DEE5),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$stepNumber',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A9B5),
        ),
      ),
    );
  }
}
