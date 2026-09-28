import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/consultation_constants.dart';

/// Widget item metode pembayaran yang bisa dipilih (radio-like).
class PaymentMethodItem extends StatelessWidget {
  final PaymentMethodData method;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodItem({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  String get _bankAssetPath {
    final fileName = method.id == 'jatim' ? 'bjatim.png' : '${method.id}.png';
    return 'assets/images/banks/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pilih metode pembayaran ${method.name}',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2ECF2),
              width: isSelected ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo bank (40x28, contain, di dalam wadah rounded)
              Container(
                width: 44,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE8EFF5),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  _bankAssetPath,
                  width: 40,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.account_balance_rounded,
                      size: 20,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Nama bank
              Expanded(
                child: Text(
                  method.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.primaryText,
                  ),
                ),
              ),

              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.lightGray,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

