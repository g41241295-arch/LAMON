import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_log_model.dart';
import '../models/berita_article_model.dart';
import '../models/ensiklopedia_entry_model.dart';
import 'rating_monitoring_service.dart';

enum AdminNotificationType {
  penilaianBaru,
  draftBerita,
  aktivitasAdminLain,
  kelengkapanGastropedia,
}

class AdminNotificationItem {
  final String id;
  final AdminNotificationType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isRead;
  final bool isLowRating; // true jika penilaian 1-2 bintang
  final int? ratingValue;
  final String? targetModule; // 'ensiklopedia' | 'berita' | 'activity'

  const AdminNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isRead,
    this.isLowRating = false,
    this.ratingValue,
    this.targetModule,
  });

  AdminNotificationItem copyWith({bool? isRead}) {
    return AdminNotificationItem(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      isLowRating: isLowRating,
      ratingValue: ratingValue,
      targetModule: targetModule,
    );
  }
}

class _AdminReadState {
  final DateTime? lastMarkedAllReadAt;
  final Set<String> readIds;

  const _AdminReadState({
    this.lastMarkedAllReadAt,
    this.readIds = const {},
  });

  bool isItemRead(String id, DateTime timestamp) {
    if (readIds.contains(id)) return true;
    if (lastMarkedAllReadAt != null &&
        !timestamp.isAfter(lastMarkedAllReadAt!)) {
      return true;
    }
    return false;
  }
}

/// Service pusat notifikasi in-app untuk Admin.
/// Menghitung notifikasi secara hemat dari data yang sudah ada di Firestore:
/// 1. Penilaian baru / perubahan nilai pengguna (Gastropedia & Konsultasi Dokter)
/// 2. Pengingat artikel berita berstatus draft
/// 3. Aktivitas perubahan konten oleh admin lain
/// 4. Pengingat kelengkapan data Gastropedia
class AdminNotificationService {
  AdminNotificationService._();
  static final AdminNotificationService instance = AdminNotificationService._();
  factory AdminNotificationService() => instance;

  static const int kMaxNotifications = 50;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RatingMonitoringService _ratingService =
      RatingMonitoringService.instance;

  // Stream controller lokal agar perubahan status baca langsung memperbarui UI & badge
  final StreamController<void> _localReadStateTrigger =
      StreamController<void>.broadcast();

  // ─────────────────────────────────────────────────────────────────────────
  // 1. STREAM DAFTAR NOTIFIKASI & BADGE BELUM DIBACA
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream daftar notifikasi admin (maksimal 50 terbaru, diurutkan kronologis terbaru di atas).
  Stream<List<AdminNotificationItem>> watchAdminNotifications() {
    late StreamController<List<AdminNotificationItem>> controller;

    StreamSubscription<List<UserRatingRecord>>? gastroRatingSub;
    StreamSubscription<List<UserRatingRecord>>? consultRatingSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? beritaSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? activitySub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? gastroEntriesSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? readStateSub;
    StreamSubscription<void>? localTriggerSub;

    List<UserRatingRecord> gastroRatings = [];
    List<UserRatingRecord> consultRatings = [];
    List<BeritaArticle> draftArticles = [];
    List<ActivityLogModel> activityLogs = [];
    List<EnsiklopediaEntry> gastroEntries = [];
    _AdminReadState readState = const _AdminReadState();

    bool hasLoadedInitialReadState = false;
    String currentAdminUid = '';
    String currentAdminName = '';

    Future<void> refreshLocalReadState() async {
      if (currentAdminUid.isEmpty) return;
      final local = await _loadReadState(currentAdminUid);
      readState = _mergeReadStates(readState, local);
    }

    void rebuildAndEmit() {
      if (controller.isClosed) return;

      final rawItems = <AdminNotificationItem>[];
      final now = DateTime.now();

      // ── A. PENILAIAN BARU / PERUBAHAN NILAI (GASTROPEDIA & KONSULTASI) ────
      final combinedRatings = <UserRatingRecord>[
        ...gastroRatings,
        ...consultRatings,
      ]..sort((a, b) => b.ratedAt.compareTo(a.ratedAt));

      for (final r in combinedRatings.take(25)) {
        final isGastro = r.featureType == RatingFeatureType.gastropedia;
        final isUpdated =
            r.previousRating != null && r.previousRating != r.rating;
        final isLow = r.rating <= 2;

        final String title;
        final String subtitle;

        if (isGastro) {
          if (isUpdated) {
            title =
                '${r.displayUserName} mengubah nilai menjadi ${r.rating} bintang pada ${r.targetTitle}';
            subtitle =
                'Penilaian Gastropedia (${r.itemCategory}) diubah dari ${r.previousRating} menjadi ${r.rating} bintang.';
          } else {
            title =
                '${r.displayUserName} memberi ${r.rating} bintang pada ${r.targetTitle}';
            subtitle = isLow
                ? 'Penilaian rendah (${r.rating}/5) pada item Gastropedia (${r.itemCategory}). Ketuk untuk memantau.'
                : 'Penilaian baru (${r.rating}/5) pada item Gastropedia (${r.itemCategory}).';
          }
        } else {
          title =
              '${r.displayUserName} memberi ${r.rating} bintang pada konsultasi ${r.targetTitle}';
          subtitle = isLow
              ? 'Penilaian rendah (${r.rating}/5) untuk sesi Konsultasi Dokter (${r.doctorSpecialty}).'
              : 'Penilaian baru (${r.rating}/5) untuk sesi Konsultasi Dokter (${r.doctorSpecialty}).';
        }

        final id =
            'rating_${r.featureType.name}_${r.id}_${r.ratedAt.millisecondsSinceEpoch}';
        final ts = r.ratedAt.millisecondsSinceEpoch > 0 ? r.ratedAt : now;

        rawItems.add(
          AdminNotificationItem(
            id: id,
            type: AdminNotificationType.penilaianBaru,
            title: title,
            subtitle: subtitle,
            timestamp: ts,
            isRead: readState.isItemRead(id, ts),
            isLowRating: isLow,
            ratingValue: r.rating,
          ),
        );
      }

      // ── B. DRAFT BERITA BELUM TERBIT ──────────────────────────────────────
      if (draftArticles.isNotEmpty) {
        DateTime latestDraftDate = DateTime.fromMillisecondsSinceEpoch(0);
        for (final d in draftArticles) {
          final dt = d.tanggal ?? DateTime.fromMillisecondsSinceEpoch(0);
          if (dt.isAfter(latestDraftDate)) {
            latestDraftDate = dt;
          }
        }
        if (latestDraftDate.millisecondsSinceEpoch <= 0) {
          latestDraftDate = DateTime(now.year, now.month, now.day, 8, 0);
        }

        final count = draftArticles.length;
        final sampleTitles = draftArticles
            .take(2)
            .map((a) => '"${a.judul}"')
            .join(', ');
        final moreText = count > 2 ? ' dan ${count - 2} lainnya' : '';

        final id = 'draft_berita_${count}_${draftArticles.first.id}';
        rawItems.add(
          AdminNotificationItem(
            id: id,
            type: AdminNotificationType.draftBerita,
            title: '$count artikel masih berstatus draft',
            subtitle:
                'Artikel $sampleTitles$moreText belum diterbitkan. Ketuk untuk mengelola Berita Kesehatan.',
            timestamp: latestDraftDate,
            isRead: readState.isItemRead(id, latestDraftDate),
            targetModule: 'berita',
          ),
        );
      }

      // ── C. AKTIVITAS ADMIN LAIN ───────────────────────────────────────────
      for (final log in activityLogs) {
        final actorId = log.olehId.trim();
        final actorName = log.oleh.trim();
        final actorLower = actorName.toLowerCase();

        // Lewati aktivitas sistem/seed dan aktivitas milik admin yang sedang login
        if (actorId == 'seed_script' ||
            actorLower == 'system' ||
            actorLower.isEmpty) {
          continue;
        }
        if (currentAdminUid.isNotEmpty && actorId == currentAdminUid) {
          continue;
        }
        if (currentAdminName.isNotEmpty &&
            actorLower == currentAdminName.toLowerCase()) {
          continue;
        }

        final aksiMap = {
          'tambah': 'menambahkan',
          'ubah': 'mengubah',
          'hapus': 'menghapus',
        };
        final modulMap = {
          'ensiklopedia': 'data gastropedia',
          'berita': 'artikel berita',
        };
        final aksiText =
            aksiMap[log.aksi.toLowerCase()] ?? log.aksi.toLowerCase();
        final modulText =
            modulMap[log.modul.toLowerCase()] ?? log.modul.toLowerCase();

        final ts = log.createdAt ?? now;
        final id = 'activity_${log.id}';

        rawItems.add(
          AdminNotificationItem(
            id: id,
            type: AdminNotificationType.aktivitasAdminLain,
            title: '$actorName $aksiText $modulText "${log.judul}"',
            subtitle:
                'Perubahan konten oleh admin lain pada modul ${modulText[0].toUpperCase()}${modulText.substring(1)}.',
            timestamp: ts,
            isRead: readState.isItemRead(id, ts),
            targetModule: log.modul.toLowerCase(),
          ),
        );
      }

      // ── D. KELENGKAPAN DATA GASTROPEDIA ───────────────────────────────────
      if (gastroEntries.isNotEmpty) {
        final incompleteEntries = <EnsiklopediaEntry>[];
        for (final entry in gastroEntries) {
          final hasImage =
              (entry.imageAsset != null &&
                  entry.imageAsset!.trim().isNotEmpty) ||
              (entry.imageBase64 != null &&
                  entry.imageBase64!.trim().isNotEmpty);
          final hasDesc = entry.definisiSingkat.trim().isNotEmpty ||
              entry.penjelasanLengkap.trim().isNotEmpty;
          final hasManfaat = entry.manfaat.isNotEmpty;
          final hasKandungan = entry.kandungan.isNotEmpty;
          final hasNutrition = entry.calories > 0;

          if (!hasImage ||
              !hasDesc ||
              !hasManfaat ||
              !hasKandungan ||
              !hasNutrition) {
            incompleteEntries.add(entry);
          }
        }

        if (incompleteEntries.isNotEmpty) {
          DateTime latestIncompleteDate =
              DateTime.fromMillisecondsSinceEpoch(0);
          for (final e in incompleteEntries) {
            final dt = e.updatedAt ?? e.createdAt;
            if (dt.isAfter(latestIncompleteDate)) {
              latestIncompleteDate = dt;
            }
          }
          if (latestIncompleteDate.millisecondsSinceEpoch <= 0) {
            latestIncompleteDate = DateTime(now.year, now.month, now.day, 8, 0);
          }

          final count = incompleteEntries.length;
          final sampleNames = incompleteEntries
              .take(2)
              .map((e) => '"${e.istilah}"')
              .join(', ');
          final moreText = count > 2 ? ' dan ${count - 2} lainnya' : '';
          final id =
              'incomplete_gastro_${count}_${incompleteEntries.first.id}';

          rawItems.add(
            AdminNotificationItem(
              id: id,
              type: AdminNotificationType.kelengkapanGastropedia,
              title: '$count data gastropedia belum lengkap',
              subtitle:
                  'Lengkapi gambar, deskripsi, manfaat, kandungan, atau nutrisi pada $sampleNames$moreText.',
              timestamp: latestIncompleteDate,
              isRead: readState.isItemRead(id, latestIncompleteDate),
              targetModule: 'ensiklopedia',
            ),
          );
        }
      }

      // Urutkan kronologis terbaru di atas dan batasi maksimal 50 item
      rawItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final capped = rawItems.take(kMaxNotifications).toList();
      controller.add(capped);
    }

    controller = StreamController<List<AdminNotificationItem>>(
      onListen: () async {
        final user = _auth.currentUser;
        currentAdminUid = user?.uid ?? '';
        if (currentAdminUid.isNotEmpty) {
          try {
            final userDoc =
                await _db.collection('users').doc(currentAdminUid).get();
            if (userDoc.exists && userDoc.data() != null) {
              currentAdminName =
                  (userDoc.data()!['nama'] ?? userDoc.data()!['name'] ?? '')
                      .toString()
                      .trim();
            }
          } catch (_) {}
          await refreshLocalReadState();
        }
        hasLoadedInitialReadState = true;

        localTriggerSub = _localReadStateTrigger.stream.listen((_) async {
          await refreshLocalReadState();
          rebuildAndEmit();
        });

        if (currentAdminUid.isNotEmpty) {
          readStateSub = _db
              .collection('admin_notification_state')
              .doc(currentAdminUid)
              .snapshots()
              .listen(
            (doc) {
              if (doc.exists && doc.data() != null) {
                final remote = _parseReadStateFromMap(doc.data()!);
                readState = _mergeReadStates(readState, remote);
                rebuildAndEmit();
              }
            },
            onError: (_) {},
          );
        }

        gastroRatingSub = _ratingService.watchGastropediaRatings().listen(
          (list) {
            gastroRatings = list;
            if (hasLoadedInitialReadState) rebuildAndEmit();
          },
          onError: (_) {},
        );

        consultRatingSub = _ratingService.watchConsultationRatings().listen(
          (list) {
            consultRatings = list;
            if (hasLoadedInitialReadState) rebuildAndEmit();
          },
          onError: (_) {},
        );

        beritaSub = _db.collection('berita_articles').snapshots().listen(
          (snap) {
            final drafts = <BeritaArticle>[];
            for (final doc in snap.docs) {
              try {
                final article = BeritaArticle.fromFirestore(doc);
                if (article.status == 'draft') {
                  drafts.add(article);
                }
              } catch (_) {}
            }
            draftArticles = drafts;
            if (hasLoadedInitialReadState) rebuildAndEmit();
          },
          onError: (_) {},
        );

        activitySub = _db
            .collection('activity_log')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots()
            .listen(
          (snap) {
            activityLogs = snap.docs
                .map((d) => ActivityLogModel.fromFirestore(d))
                .toList();
            if (hasLoadedInitialReadState) rebuildAndEmit();
          },
          onError: (_) {},
        );

        gastroEntriesSub = _db.collection('encyclopedia').snapshots().listen(
          (snap) {
            gastroEntries = snap.docs
                .map((d) => EnsiklopediaEntry.fromFirestore(d))
                .toList();
            if (hasLoadedInitialReadState) rebuildAndEmit();
          },
          onError: (_) {},
        );
      },
      onCancel: () async {
        await gastroRatingSub?.cancel();
        await consultRatingSub?.cancel();
        await beritaSub?.cancel();
        await activitySub?.cancel();
        await gastroEntriesSub?.cancel();
        await readStateSub?.cancel();
        await localTriggerSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Stream ringan untuk mengecek apakah ada minimal 1 notifikasi yang belum dibaca
  /// (menentukan tampil/tidaknya titik oranye pada ikon lonceng di Beranda Admin).
  Stream<bool> watchHasUnreadNotifications() {
    return watchAdminNotifications().map(
      (items) => items.any((item) => !item.isRead),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. PENYIMPANAN STATUS BACA PER ADMIN
  // ─────────────────────────────────────────────────────────────────────────

  /// Menandai satu notifikasi sebagai sudah dibaca oleh admin yang sedang login.
  Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty || notificationId.isEmpty) return;

    try {
      final current = await _loadReadState(uid);
      final updatedIds = <String>{...current.readIds, notificationId};
      final cappedList = updatedIds.toList();
      if (cappedList.length > 200) {
        cappedList.removeRange(0, cappedList.length - 200);
      }

      await _saveReadStateToLocal(
        uid: uid,
        readIds: cappedList,
        lastMarkedAllReadAt: current.lastMarkedAllReadAt,
      );
      _localReadStateTrigger.add(null);

      // Simpan ke koleksi admin_notification_state/{uid}
      try {
        await _db.collection('admin_notification_state').doc(uid).set({
          'adminUid': uid,
          'readIds': FieldValue.arrayUnion([notificationId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Fallback ke dokumen users/{uid} jika rules koleksi baru belum di-deploy
        try {
          await _db.collection('users').doc(uid).set({
            'adminNotifReadIds': cappedList,
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[AdminNotificationService] markAsRead error: $e');
    }
  }

  /// Menandai seluruh notifikasi saat ini sebagai sudah dibaca oleh admin yang sedang login.
  Future<void> markAllAsRead(List<AdminNotificationItem> currentItems) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final now = DateTime.now();
      final current = await _loadReadState(uid);
      final updatedIds = <String>{
        ...current.readIds,
        ...currentItems.map((e) => e.id),
      };
      final cappedList = updatedIds.toList();
      if (cappedList.length > 200) {
        cappedList.removeRange(0, cappedList.length - 200);
      }

      await _saveReadStateToLocal(
        uid: uid,
        readIds: cappedList,
        lastMarkedAllReadAt: now,
      );
      _localReadStateTrigger.add(null);

      try {
        await _db.collection('admin_notification_state').doc(uid).set({
          'adminUid': uid,
          'lastMarkedAllReadAt': Timestamp.fromDate(now),
          'readIds': cappedList,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        try {
          await _db.collection('users').doc(uid).set({
            'adminNotifLastReadAt': Timestamp.fromDate(now),
            'adminNotifReadIds': cappedList,
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[AdminNotificationService] markAllAsRead error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. HELPER PERSISTENSI STATUS BACA
  // ─────────────────────────────────────────────────────────────────────────

  _AdminReadState _parseReadStateFromMap(Map<String, dynamic> data) {
    DateTime? lastReadAt;
    final rawTs = data['lastMarkedAllReadAt'] ?? data['adminNotifLastReadAt'];
    if (rawTs is Timestamp) {
      lastReadAt = rawTs.toDate();
    } else if (rawTs is int) {
      lastReadAt = DateTime.fromMillisecondsSinceEpoch(rawTs);
    }

    final ids = <String>{};
    final rawIds = data['readIds'] ?? data['adminNotifReadIds'];
    if (rawIds is Iterable) {
      for (final item in rawIds) {
        if (item != null) ids.add(item.toString());
      }
    }

    return _AdminReadState(
      lastMarkedAllReadAt: lastReadAt,
      readIds: ids,
    );
  }

  _AdminReadState _mergeReadStates(_AdminReadState a, _AdminReadState b) {
    DateTime? latest;
    if (a.lastMarkedAllReadAt != null && b.lastMarkedAllReadAt != null) {
      latest = a.lastMarkedAllReadAt!.isAfter(b.lastMarkedAllReadAt!)
          ? a.lastMarkedAllReadAt
          : b.lastMarkedAllReadAt;
    } else {
      latest = a.lastMarkedAllReadAt ?? b.lastMarkedAllReadAt;
    }
    return _AdminReadState(
      lastMarkedAllReadAt: latest,
      readIds: {...a.readIds, ...b.readIds},
    );
  }

  Future<_AdminReadState> _loadReadState(String uid) async {
    DateTime? localLastRead;
    final localIds = <String>{};

    try {
      final prefs = await SharedPreferences.getInstance();
      final tsMillis = prefs.getInt('admin_notif_last_read_all_$uid');
      if (tsMillis != null && tsMillis > 0) {
        localLastRead = DateTime.fromMillisecondsSinceEpoch(tsMillis);
      }
      final savedList = prefs.getStringList('admin_notif_read_ids_$uid');
      if (savedList != null) {
        localIds.addAll(savedList);
      }
    } catch (_) {}

    var combined = _AdminReadState(
      lastMarkedAllReadAt: localLastRead,
      readIds: localIds,
    );

    try {
      final stateDoc =
          await _db.collection('admin_notification_state').doc(uid).get();
      if (stateDoc.exists && stateDoc.data() != null) {
        combined = _mergeReadStates(
          combined,
          _parseReadStateFromMap(stateDoc.data()!),
        );
      }
    } catch (_) {
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          combined = _mergeReadStates(
            combined,
            _parseReadStateFromMap(userDoc.data()!),
          );
        }
      } catch (_) {}
    }

    return combined;
  }

  Future<void> _saveReadStateToLocal({
    required String uid,
    required List<String> readIds,
    required DateTime? lastMarkedAllReadAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('admin_notif_read_ids_$uid', readIds);
      if (lastMarkedAllReadAt != null) {
        await prefs.setInt(
          'admin_notif_last_read_all_$uid',
          lastMarkedAllReadAt.millisecondsSinceEpoch,
        );
      }
    } catch (_) {}
  }
}
