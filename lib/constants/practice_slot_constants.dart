import 'package:flutter/material.dart';

/// Model definisi slot jam praktik dokter.
class PracticeSlot {
  final String id;
  final String label;
  final String startTime;
  final String endTime;
  final IconData icon;
  final bool isCustom;

  const PracticeSlot({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.icon,
    this.isCustom = false,
  });

  String get timeRangeDisplay => '$startTime - $endTime WIB';

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'startTime': startTime,
        'endTime': endTime,
        'isCustom': isCustom,
      };

  factory PracticeSlot.createCustom({
    required String startTime,
    required String endTime,
    String? id,
  }) {
    final cleanStart = startTime.replaceAll(':', '.').trim();
    final cleanEnd = endTime.replaceAll(':', '.').trim();
    final customId = id ?? 'custom_${cleanStart}_$cleanEnd';
    return PracticeSlot(
      id: customId,
      label: 'Lainnya',
      startTime: cleanStart,
      endTime: cleanEnd,
      icon: Icons.more_time_rounded,
      isCustom: true,
    );
  }

  factory PracticeSlot.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final id = (raw['id'] ?? '').toString();
      final label = (raw['label'] ?? 'Lainnya').toString();
      final start = (raw['startTime'] ?? raw['start'] ?? '').toString();
      final end = (raw['endTime'] ?? raw['end'] ?? '').toString();
      final fixed = PracticeSlotConstants.findById(id);
      if (fixed != null) return fixed;
      return PracticeSlot(
        id: id.isNotEmpty ? id : 'custom_${start}_$end',
        label: label.isNotEmpty ? label : 'Lainnya',
        startTime: start,
        endTime: end,
        icon: Icons.more_time_rounded,
        isCustom: true,
      );
    }

    final str = raw.toString();
    final fixed = PracticeSlotConstants.findById(str);
    if (fixed != null) return fixed;

    // Format custom: custom_HH.mm_HH.mm atau custom:HH.mm-HH.mm
    if (str.startsWith('custom')) {
      final parts = str.replaceFirst('custom_', '').replaceFirst('custom:', '').split(RegExp(r'[_|\-]'));
      if (parts.length >= 2) {
        return PracticeSlot.createCustom(
          id: str,
          startTime: parts[0],
          endTime: parts[1],
        );
      }
    }

    return PracticeSlot(
      id: str,
      label: 'Lainnya',
      startTime: '',
      endTime: '',
      icon: Icons.more_time_rounded,
      isCustom: true,
    );
  }
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

  /// Parse list slot (berisi string atau map) menjadi List<PracticeSlot>
  static List<PracticeSlot> parseSlots(List<dynamic> rawList) {
    final list = <PracticeSlot>[];
    for (final raw in rawList) {
      if (raw == null) continue;
      final slot = PracticeSlot.fromDynamic(raw);
      if (slot.startTime.isNotEmpty && slot.endTime.isNotEmpty) {
        list.add(slot);
      }
    }
    return list;
  }
}
