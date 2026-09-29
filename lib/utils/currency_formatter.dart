/// Helper pemformatan mata uang Rupiah standar Indonesia.
/// Menghasilkan format Rp50.000 (tanpa spasi).
String formatRupiah(num amount) {
  final int val = amount.toInt();
  final bool isNegative = val < 0;
  final String absStr = val.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < absStr.length; i++) {
    if (i > 0 && (absStr.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(absStr[i]);
  }

  final prefix = isNegative ? '-Rp' : 'Rp';
  return '$prefix$buffer';
}
