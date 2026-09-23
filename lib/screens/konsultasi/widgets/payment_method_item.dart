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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              // Logo bank (label teks dalam container berwarna)
              Container(
                width: 54,
                height: 32,
                decoration: BoxDecoration(
                  color: _bankColor(method.id),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  method.iconLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
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

  Color _bankColor(String bankId) {
    switch (bankId) {
      case 'bsi':
        return const Color(0xFF00694F); // hijau BSI
      case 'mandiri':
        return const Color(0xFF003B6F); // biru Mandiri
      case 'bri':
        return const Color(0xFF00529B); // biru BRI
      case 'jatim':
        return const Color(0xFF1565C0); // biru Bank Jatim
      case 'bca':
        return const Color(0xFF006CB4); // biru BCA
      default:
        return AppColors.primaryDark;
    }
  }
}
