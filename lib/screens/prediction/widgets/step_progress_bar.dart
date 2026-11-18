import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Progress stepper 3 langkah (1-2-3) dengan gaya klinis modern
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1, 2, atau 3
  final int totalSteps;

  static const List<String> stepNames = [
    'Pola Makan',
    'Faktor Risiko',
    'Gaya Hidup',
  ];

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 1; i <= totalSteps; i++) ...[
                _buildStepNode(stepNumber: i),
                if (i < totalSteps)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i < currentStep
                            ? const Color(0xFF276F8F)
                            : const Color(0xFFEBE3D0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Row of Step Titles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isActive = stepNum == currentStep;
              final isDone = stepNum < currentStep;

              return SizedBox(
                width: 75,
                child: Text(
                  stepNames[index],
                  textAlign: index == 0
                      ? TextAlign.left
                      : (index == totalSteps - 1 ? TextAlign.right : TextAlign.center),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: (isActive || isDone) ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF1C4E68)
                        : (isDone ? const Color(0xFF276F8F) : const Color(0xFF9CB3C2)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({required int stepNumber}) {
    final isCompleted = stepNumber < currentStep;
    final isActive = stepNumber == currentStep;

    if (isCompleted) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF276F8F),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF276F8F).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 17,
          color: Colors.white,
        ),
      );
    }

    if (isActive) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF1C4E68),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C4E68).withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepNumber',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C4E68),
          ),
        ),
      );
    }

    // Step belum tercapai
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5EE),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFEBE3D0),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$stepNumber',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9CB3C2),
        ),
      ),
    );
  }
}
