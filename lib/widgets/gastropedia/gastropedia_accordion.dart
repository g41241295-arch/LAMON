import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Card accordion untuk section Deskripsi, Manfaat, dan Kandungan Gizi di Detail Makanan.
/// Memiliki fitur toggle buka/tutup (expand/collapse) dengan animasi transisi yang halus.
/// Ditampilkan dengan latar krem lembut yang senada dan nyaman di mata.
class GastropediaAccordion extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initialExpanded;

  const GastropediaAccordion({
    super.key,
    required this.title,
    required this.content,
    this.initialExpanded = true,
  });

  @override
  State<GastropediaAccordion> createState() => _GastropediaAccordionState();
}

class _GastropediaAccordionState extends State<GastropediaAccordion> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gastropediaCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gastropediaCardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card (Judul Bold dengan latar gradasi krem lembut & tombol toggle)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.gastropediaAccordionHeaderStart,
                      AppColors.gastropediaAccordionHeaderEnd,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E5D7D),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.0 : 0.5,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Color(0xFF1E5D7D),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Badan Konten (latar krem lembut dengan border pemisah krem + animasi AnimatedCrossFade)
          ClipRect(
            child: AnimatedCrossFade(
              firstChild: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.gastropediaCardBg,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gastropediaAccordionBorder,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: widget.content,
              ),
              secondChild: const SizedBox(
                width: double.infinity,
                height: 0,
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeInOut,
              firstCurve: Curves.easeInOut,
              secondCurve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}
