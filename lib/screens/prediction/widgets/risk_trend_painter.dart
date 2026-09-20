import 'package:flutter/material.dart';
import '../../../models/reflux_prediction_model.dart';

class RiskTrendPainter extends CustomPainter {
  final List<RefluxPredictionResult> records; // Terurut dari LAMA ke BARU (kiri ke kanan)

  RiskTrendPainter({required this.records});

  static Color getRiskColor(double percentage) {
    if (percentage <= 33.0) {
      return const Color(0xFF2E7D32); // Hijau (Rendah)
    } else if (percentage <= 66.0) {
      return const Color(0xFFE65100); // Oranye (Sedang)
    } else {
      return const Color(0xFFC62828); // Merah (Tinggi)
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    const double topPadding = 24.0;
    const double bottomPadding = 20.0;
    const double horizontalPadding = 18.0;

    final drawWidth = size.width - (horizontalPadding * 2);
    final drawHeight = size.height - (topPadding + bottomPadding);

    // 1. Gambar garis grid horizontal latar
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gridLines = 3;
    for (int i = 0; i <= gridLines; i++) {
      final y = topPadding + (drawHeight / gridLines) * i;
      _drawDashedLine(
        canvas,
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    if (records.length == 1) {
      // Titik tunggal di tengah
      final pointX = size.width / 2;
      final score = records.first.riskPercentage.clamp(0.0, 100.0);
      final pointY = topPadding + drawHeight * (1.0 - (score / 100.0));
      final color = getRiskColor(score);

      _drawDataPoint(canvas, Offset(pointX, pointY), color, score, isLast: true);
      return;
    }

    // 2. Hitung koordinat semua titik (Lama -> Baru)
    final points = <Offset>[];
    final stepX = drawWidth / (records.length - 1);

    for (int i = 0; i < records.length; i++) {
      final score = records[i].riskPercentage.clamp(0.0, 100.0);
      final x = horizontalPadding + (i * stepX);
      final y = topPadding + drawHeight * (1.0 - (score / 100.0));
      points.add(Offset(x, y));
    }

    // 3. Buat Path garis kurva halus
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 4. Fill gradasi di bawah kurva
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height - bottomPadding)
      ..lineTo(points.first.dx, size.height - bottomPadding)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF276F8F).withValues(alpha: 0.16),
        const Color(0xFF276F8F).withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, topPadding, size.width, drawHeight),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Gambar garis stroke utama dengan gradasi
    final strokeGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: points.map((p) {
        final index = points.indexOf(p);
        return getRiskColor(records[index].riskPercentage);
      }).toList(),
    );

    final strokePaint = Paint()
      ..shader = strokeGradient.createShader(
        Rect.fromLTWH(horizontalPadding, 0, drawWidth, size.height),
      )
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 6. Gambar lingkaran data point dan label
    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      final score = records[i].riskPercentage;
      final color = getRiskColor(score);

      _drawDataPoint(canvas, points[i], color, score, isLast: isLast);
    }
  }

  void _drawDataPoint(
    Canvas canvas,
    Offset center,
    Color color,
    double score, {
    required bool isLast,
  }) {
    if (isLast) {
      // Outer glow/ring untuk titik terakhir (pemeriksaan terbaru)
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 12, glowPaint);

      final ringPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, 9, ringPaint);
    }

    // Border putih
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, isLast ? 6.5 : 5.0, whitePaint);

    // Center dot warna risiko
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, isLast ? 4.5 : 3.5, dotPaint);

    // Label skor di atas titik
    final textSpan = TextSpan(
      text: '${score.toInt()}%',
      style: TextStyle(
        color: color,
        fontSize: isLast ? 11.5 : 10.0,
        fontWeight: isLast ? FontWeight.w900 : FontWeight.w700,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelOffset = Offset(
      center.dx - (textPainter.width / 2),
      center.dy - textPainter.height - (isLast ? 10 : 7),
    );
    textPainter.paint(canvas, labelOffset);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double currentX = p1.dx;

    while (currentX < p2.dx) {
      final endX = (currentX + dashWidth).clamp(p1.dx, p2.dx);
      canvas.drawLine(
        Offset(currentX, p1.dy),
        Offset(endX, p1.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant RiskTrendPainter oldDelegate) {
    return oldDelegate.records != records;
  }
}
