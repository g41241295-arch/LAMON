import 'package:flutter/material.dart';

/// Model definisi slot jam praktik dokter.
class PracticeSlot {
  final String id;
  final String label;
  final String startTime;
  final String endTime;
  final IconData icon;

  const PracticeSlot({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.icon,
  });

  String get timeRangeDisplay => '$startTime - $endTime WIB';
}

/// Konstanta bersama untuk slot praktik dokter di seluruh aplikasi.
class PracticeSlotConstants {
  static const PracticeSlot pagi = PracticeSlot(
    id: 'pagi',
    label: 'Pagi',
    startTime: '07.00',
    endTime: '11.00',
    icon: Icons.wb_sunny_outlined,
  );

  static const PracticeSlot siang = PracticeSlot(
    id: 'siang',
    label: 'Siang',
    startTime: '13.00',
    endTime: '17.00',
    icon: Icons.wb_sunny_rounded,
  );

  static const PracticeSlot malam = PracticeSlot(
    id: 'malam',
    label: 'Malam',
    startTime: '18.00',
    endTime: '21.00',
    icon: Icons.nightlight_round,
  );

  static const List<PracticeSlot> allSlots = [pagi, siang, malam];

  /// Mengambil slot berdasarkan ID ('pagi', 'siang', 'malam').
  static PracticeSlot? findById(String id) {
    try {
      return allSlots.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
