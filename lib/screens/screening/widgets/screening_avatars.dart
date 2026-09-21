import 'package:flutter/material.dart';

/// Avatar anak laki-laki untuk opsi "Pria"
class BoyAvatar extends StatelessWidget {
  final double size;
  const BoyAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/avatar_boy.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
}

/// Avatar anak perempuan untuk opsi "Wanita"
class GirlAvatar extends StatelessWidget {
  final double size;
  const GirlAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/avatar_girl.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
}

/// Avatar untuk opsi "Iya" (Gesture OK)
class DoctorAvatar extends StatelessWidget {
  final double size;
  const DoctorAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/avatar_yes.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
}

/// Avatar untuk opsi "Tidak" (Gesture No/Cross)
class PersonAvatar extends StatelessWidget {
  final double size;
  const PersonAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/avatar_no.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
}

/// 3D Green sphere checkmark badge untuk Step 4 (Halaman Sukses)
class GreenCheckmark3DBadge extends StatelessWidget {
  final double size;
  const GreenCheckmark3DBadge({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icon_check_3d.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
}
