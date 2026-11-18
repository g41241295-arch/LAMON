import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/consultation_constants.dart';
import '../../../constants/consultation_theme.dart';

/// Widget kartu pilihan metode pembayaran bank (gaya radio pill modern).
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
    final fileName = method.id == 'jatim'
        ? 'bank_jatim-removebg-preview.png'
        : '${method.id}-removebg-preview.png';
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
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? ConsultationTheme.primary
                  : ConsultationTheme.cardBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: ConsultationTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Kotak logo bank 60x40 (latar #F7F3EB)
              Container(
                width: 60,
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ConsultationTheme.softBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ConsultationTheme.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    _bankAssetPath,
                    width: 52,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        method.iconLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ConsultationTheme.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Nama bank bold
              Expanded(
                child: Text(
                  method.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: ConsultationTheme.primary,
                  ),
                ),
              ),

              // Radio di kanan: terpilih (border & isi biru tua), tidak terpilih (outline #D9CDB8)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? ConsultationTheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? ConsultationTheme.primary
                        : const Color(0xFFD9CDB8),
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.circle,
                          color: Colors.white,
                          size: 8,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
