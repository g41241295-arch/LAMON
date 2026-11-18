import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/consultation_model.dart';
import '../models/gastropedia_item_model.dart';

enum RatingFeatureType {
  gastropedia,
  consultation,
}

/// Satu entri perubahan nilai pada riwayat penilaian item yang sama.
class RatingHistoryEntry {
  final int rating;
  final int? previousRating;
  final DateTime ratedAt;

  const RatingHistoryEntry({
    required this.rating,
    this.previousRating,
    required this.ratedAt,
  });

  factory RatingHistoryEntry.fromMap(Map<String, dynamic> map) {
    final rawTs = map['ratedAt'] ?? map['updatedAt'];
    final DateTime dt = rawTs is Timestamp
        ? rawTs.toDate()
        : (rawTs is String
            ? (DateTime.tryParse(rawTs) ?? DateTime.now())
            : DateTime.now());
    return RatingHistoryEntry(
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      previousRating: (map['previousRating'] as num?)?.toInt(),
      ratedAt: dt,
    );
  }
}

/// Profil singkat pengguna untuk pemantauan penilaian (tanpa data sensitif seperti email/telepon).
class RatingUserBriefProfile {
  final String userId;
  final String name;
  final String? photoUrl;
  final String? photoBase64;

  const RatingUserBriefProfile({
    required this.userId,
    required this.name,
    this.photoUrl,
    this.photoBase64,
  });
}

/// Model terpadu untuk satu item penilaian pengguna (Gastropedia maupun Konsultasi Dokter).
class UserRatingRecord {
  final String id;
  final RatingFeatureType featureType;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? userPhotoBase64;
  final int rating;
  final int? previousRating;
  final DateTime ratedAt;
  final String? comment;

  // Field khusus Gastropedia
  final String itemId;
  final String itemName;
  final String itemCategory;
  final String itemImage;
  final String itemImageBase64;
  final List<RatingHistoryEntry> changeHistory;

  // Field khusus Konsultasi Dokter
  final String consultationId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorPhotoUrl;
  final DateTime? consultationDate;
  final String scheduledTime;

  const UserRatingRecord({
    required this.id,
    required this.featureType,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.userPhotoBase64,
    required this.rating,
    this.previousRating,
    required this.ratedAt,
    this.comment,
    this.itemId = '',
    this.itemName = '',
    this.itemCategory = '',
    this.itemImage = '',
    this.itemImageBase64 = '',
    this.changeHistory = const [],
    this.consultationId = '',
    this.doctorId = '',
    this.doctorName = '',
    this.doctorSpecialty = '',
    this.doctorPhotoUrl = '',
    this.consultationDate,
    this.scheduledTime = '',
  });

  String get displayUserName {
    final trimmed = userName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'Pengguna';
  }

  String get userInitials {
    final clean = displayUserName;
    final parts = clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get targetTitle {
    if (featureType == RatingFeatureType.gastropedia) {
      return itemName.trim().isNotEmpty ? itemName.trim() : '-';
    }
    return doctorName.trim().isNotEmpty ? doctorName.trim() : '-';
  }

  UserRatingRecord copyWithUserProfile(RatingUserBriefProfile profile) {
    final resolvedName = userName.trim().isNotEmpty &&
            userName.trim().toLowerCase() != 'pengguna' &&
            userName.trim().toLowerCase() != 'pasien'
        ? userName.trim()
        : (profile.name.trim().isNotEmpty ? profile.name.trim() : userName);

    final resolvedPhotoUrl = (userPhotoUrl != null && userPhotoUrl!.trim().isNotEmpty)
        ? userPhotoUrl
        : profile.photoUrl;

    final resolvedPhotoBase64 =
        (userPhotoBase64 != null && userPhotoBase64!.trim().isNotEmpty)
            ? userPhotoBase64
            : profile.photoBase64;

    return UserRatingRecord(
      id: id,
      featureType: featureType,
      userId: userId,
      userName: resolvedName,
      userPhotoUrl: resolvedPhotoUrl,
      userPhotoBase64: resolvedPhotoBase64,
      rating: rating,
      previousRating: previousRating,
      ratedAt: ratedAt,
      comment: comment,
      itemId: itemId,
      itemName: itemName,
      itemCategory: itemCategory,
      itemImage: itemImage,
      itemImageBase64: itemImageBase64,
      changeHistory: changeHistory,
      consultationId: consultationId,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      doctorPhotoUrl: doctorPhotoUrl,
      consultationDate: consultationDate,
      scheduledTime: scheduledTime,
    );
  }
}

/// Ringkasan statistik penilaian untuk sebuah tab (Gastropedia atau Konsultasi Dokter).
class RatingSummaryStats {
  final int totalCount;
  final double averageRating;
  final Map<int, int> starCounts;

  const RatingSummaryStats({
    required this.totalCount,
    required this.averageRating,
    required this.starCounts,
  });

  factory RatingSummaryStats.fromRecords(List<UserRatingRecord> records) {
    final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    int sum = 0;
    int validTotal = 0;

    for (final r in records) {
      if (r.rating >= 1 && r.rating <= 5) {
        counts[r.rating] = (counts[r.rating] ?? 0) + 1;
        sum += r.rating;
        validTotal++;
      }
    }

    final avg = validTotal > 0 ? (sum / validTotal) : 0.0;
    return RatingSummaryStats(
      totalCount: validTotal,
      averageRating: avg,
      starCounts: counts,
    );
  }

  double ratioForStar(int star) {
    if (totalCount <= 0) return 0.0;
    final c = starCounts[star] ?? 0;
    return (c / totalCount).clamp(0.0, 1.0);
  }
}

/// Service untuk mencatat (aditif) dan memantau penilaian pengguna pada
/// fitur Gastropedia dan Konsultasi Dokter.
class RatingMonitoringService {
  RatingMonitoringService._();
  static final RatingMonitoringService instance = RatingMonitoringService._();
  factory RatingMonitoringService() => instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache profil singkat pengguna & metadata item/dokter untuk fallback data lama
  static final Map<String, RatingUserBriefProfile> _userProfileCache = {};
  static final Map<String, GastropediaItem> _encyclopediaCache = {};
  static final Map<String, Map<String, String>> _doctorCache = {};

  CollectionReference<Map<String, dynamic>> get _gastropediaRatingsRef =>
      _db.collection('gastropedia_ratings');

  // ─────────────────────────────────────────────────────────────────────────
  // 1. PENYIMPANAN ADITIF PENILAIAN GASTROPEDIA (SISI PENGGUNA)
  // ─────────────────────────────────────────────────────────────────────────

  /// Menyimpan penilaian bintang Gastropedia ke koleksi `gastropedia_ratings`
  /// secara aditif tanpa mengubah perilaku lokal SharedPreferences.
  /// Jika pengguna mengubah penilaian pada item yang sama, riwayat perubahan
  /// tetap tercatat di field `history`.
  Future<void> saveGastropediaRating({
    required GastropediaItem item,
    required int rating,
  }) async {
    if (rating < 1 || rating > 5) return;
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) return;

    try {
      final uid = user.uid;
      final profile = await _fetchUserBriefProfile(uid, fallbackAuthUser: user);
      final docId = '${uid}_${item.id}';
      final docRef = _gastropediaRatingsRef.doc(docId);

      final existingSnap = await docRef.get();
      final nowTs = Timestamp.now();

      List<Map<String, dynamic>> historyList = [];
      int? previousRating;
      Timestamp? existingCreatedAt;

      if (existingSnap.exists && existingSnap.data() != null) {
        final oldData = existingSnap.data()!;
        existingCreatedAt = oldData['createdAt'] as Timestamp?;
        final oldRating = (oldData['rating'] as num?)?.toInt();
        previousRating = oldRating;

        final rawHistory = oldData['history'];
        if (rawHistory is Iterable) {
          for (final entry in rawHistory) {
            if (entry is Map) {
              historyList.add(Map<String, dynamic>.from(entry));
            }
          }
        } else if (oldRating != null && oldRating >= 1 && oldRating <= 5) {
          historyList.add({
            'rating': oldRating,
            'ratedAt': oldData['ratedAt'] ?? oldData['updatedAt'] ?? existingCreatedAt ?? nowTs,
          });
        }
      }

      historyList.add({
        'rating': rating,
        if (previousRating != null && previousRating != rating)
          'previousRating': previousRating,
        'ratedAt': nowTs,
      });

      await docRef.set({
        'userId': uid,
        'userName': profile.name,
        if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
          'userPhotoUrl': profile.photoUrl,
        if (profile.photoBase64 != null && profile.photoBase64!.isNotEmpty)
          'userPhotoBase64': profile.photoBase64,
        'itemId': item.id,
        'itemName': item.name,
        'itemCategory': item.category.label,
        'itemImage': item.imageAsset,
        if (item.imageBase64.isNotEmpty) 'itemImageBase64': item.imageBase64,
        'rating': rating,
        if (previousRating != null && previousRating != rating)
          'previousRating': previousRating,
        'createdAt': existingCreatedAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ratedAt': FieldValue.serverTimestamp(),
        'history': historyList,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[RatingMonitoringService] Gagal simpan rating Gastropedia ke Firestore: $e');
    }
  }

  /// Sinkronisasi aditif untuk rating lokal di SharedPreferences yang sudah ada
  /// sebelum koleksi `gastropedia_ratings` dibuat, agar tetap terbaca oleh Admin.
  Future<void> ensureLocalGastropediaRatingSynced({
    required GastropediaItem item,
    required int localRating,
  }) async {
    if (localRating < 1 || localRating > 5) return;
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) return;

    try {
      final docId = '${user.uid}_${item.id}';
      final docRef = _gastropediaRatingsRef.doc(docId);
      final snap = await docRef.get();
      if (!snap.exists) {
        await saveGastropediaRating(item: item, rating: localRating);
      }
    } catch (e) {
      debugPrint('[RatingMonitoringService] ensureLocalGastropediaRatingSynced error: $e');
    }
  }

  /// Memindai seluruh item Gastropedia di SharedPreferences perangkat saat ini
  /// dan memastikan rating lokal pengguna sudah tersinkron ke Firestore.
  Future<void> syncAllLocalGastropediaRatingsForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final item in GastropediaData.items) {
        final key = 'gastropedia_user_rating_${item.id}';
        final saved = prefs.getInt(key);
        if (saved != null && saved >= 1 && saved <= 5) {
          await ensureLocalGastropediaRatingSynced(
            item: item,
            localRating: saved,
          );
        }
      }
    } catch (e) {
      debugPrint('[RatingMonitoringService] syncAllLocalGastropediaRatings error: $e');
    }
  }

  /// Mengambil nilai bintang Gastropedia milik pengguna yang sedang login dari Firestore
  /// jika di SharedPreferences lokal belum ada (misal ganti perangkat).
  Future<int?> fetchUserGastropediaRating(String itemId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) return null;
    try {
      final doc = await _gastropediaRatingsRef.doc('${user.uid}_$itemId').get();
      if (doc.exists && doc.data() != null) {
        final rating = (doc.data()!['rating'] as num?)?.toInt();
        if (rating != null && rating >= 1 && rating <= 5) {
          return rating;
        }
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. STREAM PEMANTAUAN PENILAIAN (SISI ADMIN - READ ONLY)
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream seluruh penilaian Gastropedia untuk Admin (diurutkan terbaru).
  Stream<List<UserRatingRecord>> watchGastropediaRatings() {
    return _gastropediaRatingsRef.snapshots().asyncMap((snap) async {
      final records = <UserRatingRecord>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num?)?.toInt() ?? 0;
        if (rating < 1 || rating > 5) continue;

        final userId = (data['userId'] ?? '').toString().trim();
        final itemId = (data['itemId'] ?? '').toString().trim();

        // Waktu penilaian
        final rawTs = data['ratedAt'] ?? data['updatedAt'] ?? data['createdAt'];
        final DateTime ratedAt = rawTs is Timestamp
            ? rawTs.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);

        // Riwayat perubahan nilai pada item ini
        final historyEntries = <RatingHistoryEntry>[];
        final rawHistory = data['history'];
        if (rawHistory is Iterable) {
          for (final h in rawHistory) {
            if (h is Map) {
              final parsed =
                  RatingHistoryEntry.fromMap(Map<String, dynamic>.from(h));
              if (parsed.rating >= 1 && parsed.rating <= 5) {
                historyEntries.add(parsed);
              }
            }
          }
          historyEntries.sort((a, b) => b.ratedAt.compareTo(a.ratedAt));
        }

        // Fallback metadata item Gastropedia jika data lama belum lengkap
        String itemName = (data['itemName'] ?? '').toString().trim();
        String itemCategory = (data['itemCategory'] ?? '').toString().trim();
        String itemImage = (data['itemImage'] ?? '').toString().trim();
        String itemImageBase64 = (data['itemImageBase64'] ?? '').toString().trim();

        if ((itemName.isEmpty || itemCategory.isEmpty || itemImage.isEmpty) &&
            itemId.isNotEmpty) {
          final fallbackItem = await _resolveGastropediaItem(itemId);
          if (fallbackItem != null) {
            if (itemName.isEmpty) itemName = fallbackItem.name;
            if (itemCategory.isEmpty) itemCategory = fallbackItem.category.label;
            if (itemImage.isEmpty) itemImage = fallbackItem.imageAsset;
            if (itemImageBase64.isEmpty) {
              itemImageBase64 = fallbackItem.imageBase64;
            }
          }
        }

        final comment = (data['comment'] ?? data['ulasan'] ?? data['review'] ?? '')
            .toString()
            .trim();

        var record = UserRatingRecord(
          id: doc.id,
          featureType: RatingFeatureType.gastropedia,
          userId: userId,
          userName: (data['userName'] ?? '').toString().trim(),
          userPhotoUrl: (data['userPhotoUrl'] ?? '').toString().trim(),
          userPhotoBase64: (data['userPhotoBase64'] ?? '').toString().trim(),
          rating: rating,
          previousRating: (data['previousRating'] as num?)?.toInt(),
          ratedAt: ratedAt,
          comment: comment.isNotEmpty ? comment : null,
          itemId: itemId,
          itemName: itemName.isNotEmpty ? itemName : '-',
          itemCategory: itemCategory.isNotEmpty ? itemCategory : 'Makanan',
          itemImage: itemImage,
          itemImageBase64: itemImageBase64,
          changeHistory: historyEntries,
        );

        // Lengkapi nama/foto pengguna dari koleksi users/{userId} jika belum lengkap
        if (userId.isNotEmpty &&
            (record.userName.isEmpty ||
                record.userName.toLowerCase() == 'pengguna' ||
                ((record.userPhotoUrl == null || record.userPhotoUrl!.isEmpty) &&
                    (record.userPhotoBase64 == null ||
                        record.userPhotoBase64!.isEmpty)))) {
          final profile = await _fetchUserBriefProfile(userId);
          record = record.copyWithUserProfile(profile);
        }

        records.add(record);
      }

      records.sort((a, b) => b.ratedAt.compareTo(a.ratedAt));
      return records;
    });
  }

  /// Stream seluruh penilaian Konsultasi Dokter untuk Admin (diurutkan terbaru).
  /// Menggunakan `collectionGroup('consultations').orderBy('doctorId')` yang sudah
  /// memiliki index COLLECTION_GROUP pada `firestore.indexes.json`.
  Stream<List<UserRatingRecord>> watchConsultationRatings() {
    return _db
        .collectionGroup('consultations')
        .orderBy('doctorId')
        .snapshots()
        .asyncMap((snap) async {
      final records = <UserRatingRecord>[];

      for (final doc in snap.docs) {
        final rawData = doc.data();
        final rawRating = rawData['rating'];
        if (rawRating is! num) continue;
        final rating = rawRating.toInt();
        if (rating < 1 || rating > 5) continue;

        final model = ConsultationModel.fromFirestore(doc);
        final ratedAt = model.ratedAt ?? model.completedAt ?? model.createdAt;
        final consultDate =
            model.scheduledDate ?? model.completedAt ?? model.createdAt;

        String doctorName = model.doctorName.trim();
        String doctorSpecialty = model.doctorSpecialty.trim();
        String doctorPhotoUrl = model.effectiveDoctorPhotoUrl;

        if ((doctorName.isEmpty || doctorSpecialty.isEmpty) &&
            model.doctorId.isNotEmpty) {
          final docMeta = await _resolveDoctorMeta(model.doctorId);
          if (doctorName.isEmpty) doctorName = docMeta['name'] ?? '-';
          if (doctorSpecialty.isEmpty) {
            doctorSpecialty = docMeta['specialty'] ?? 'Dokter Umum';
          }
          if (doctorPhotoUrl.isEmpty) {
            doctorPhotoUrl = docMeta['photoUrl'] ?? '';
          }
        }

        final comment = (rawData['review'] ??
                rawData['ratingComment'] ??
                rawData['ulasan'] ??
                '')
            .toString()
            .trim();

        var record = UserRatingRecord(
          id: doc.id,
          featureType: RatingFeatureType.consultation,
          userId: model.patientUid,
          userName: model.patientName.trim(),
          userPhotoUrl: model.patientPhotoUrl,
          userPhotoBase64: (rawData['patientPhotoBase64'] ?? '').toString().trim(),
          rating: rating,
          ratedAt: ratedAt,
          comment: comment.isNotEmpty ? comment : null,
          consultationId: model.id,
          doctorId: model.doctorId,
          doctorName: doctorName.isNotEmpty ? doctorName : '-',
          doctorSpecialty:
              doctorSpecialty.isNotEmpty ? doctorSpecialty : 'Dokter',
          doctorPhotoUrl: doctorPhotoUrl,
          consultationDate: consultDate,
          scheduledTime: model.scheduledTime,
        );

        // Lengkapi nama & foto profil pasien dari users/{patientUid}
        if (model.patientUid.isNotEmpty) {
          final profile = await _fetchUserBriefProfile(model.patientUid);
          record = record.copyWithUserProfile(profile);
        }

        records.add(record);
      }

      records.sort((a, b) => b.ratedAt.compareTo(a.ratedAt));
      return records;
    });
  }

  /// Stream total penilaian gabungan (Gastropedia + Konsultasi Dokter)
  /// untuk ditampilkan pada subtitle card "Pemantauan Penilaian" di Beranda Admin.
  Stream<int> watchTotalCombinedRatingsCount() {
    late StreamController<int> controller;
    StreamSubscription<List<UserRatingRecord>>? gastroSub;
    StreamSubscription<List<UserRatingRecord>>? consultSub;

    int gastroCount = 0;
    int consultCount = 0;
    bool hasGastro = false;
    bool hasConsult = false;

    void emitIfReady() {
      if (!controller.isClosed && (hasGastro || hasConsult)) {
        controller.add(gastroCount + consultCount);
      }
    }

    controller = StreamController<int>(
      onListen: () {
        gastroSub = watchGastropediaRatings().listen(
          (list) {
            gastroCount = list.length;
            hasGastro = true;
            emitIfReady();
          },
          onError: (e) {
            debugPrint('[RatingMonitoringService] gastro count stream error: $e');
            hasGastro = true;
            emitIfReady();
          },
        );

        consultSub = watchConsultationRatings().listen(
          (list) {
            consultCount = list.length;
            hasConsult = true;
            emitIfReady();
          },
          onError: (e) {
            debugPrint('[RatingMonitoringService] consult count stream error: $e');
            hasConsult = true;
            emitIfReady();
          },
        );
      },
      onCancel: () async {
        await gastroSub?.cancel();
        await consultSub?.cancel();
      },
    );

    return controller.stream;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. HELPER RESOLUSI DATA LAMA (USERS, ENCYCLOPEDIA, DOCTORS)
  // ─────────────────────────────────────────────────────────────────────────

  Future<RatingUserBriefProfile> _fetchUserBriefProfile(
    String userId, {
    User? fallbackAuthUser,
  }) async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      return const RatingUserBriefProfile(userId: '', name: 'Pengguna');
    }

    if (_userProfileCache.containsKey(cleanUid)) {
      return _userProfileCache[cleanUid]!;
    }

    String name = '';
    String? photoUrl;
    String? photoBase64;

    try {
      final doc = await _db.collection('users').doc(cleanUid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawNama =
            (data['nama'] ?? data['name'] ?? data['displayName'] ?? '')
                .toString()
                .trim();
        if (rawNama.isNotEmpty) {
          name = rawNama;
        } else {
          // Gunakan bagian lokal sebelum @ hanya sebagai fallback nama panggilan jika nama kosong
          final rawEmail = (data['email'] ?? '').toString().trim();
          if (rawEmail.contains('@')) {
            final local = rawEmail.split('@').first.trim();
            if (local.isNotEmpty) {
              name = local[0].toUpperCase() + local.substring(1);
            }
          }
        }

        final rawPhotoUrl =
            (data['photo_url'] ?? data['photoUrl'] ?? '').toString().trim();
        if (rawPhotoUrl.isNotEmpty) photoUrl = rawPhotoUrl;

        final rawPhotoBase64 = (data['photoBase64'] ?? '').toString().trim();
        if (rawPhotoBase64.isNotEmpty) photoBase64 = rawPhotoBase64;
      }
    } catch (e) {
      debugPrint('[RatingMonitoringService] _fetchUserBriefProfile error ($cleanUid): $e');
    }

    if (name.isEmpty && fallbackAuthUser != null) {
      final dName = (fallbackAuthUser.displayName ?? '').trim();
      if (dName.isNotEmpty) {
        name = dName;
      } else if ((fallbackAuthUser.email ?? '').contains('@')) {
        final local = fallbackAuthUser.email!.split('@').first.trim();
        if (local.isNotEmpty) {
          name = local[0].toUpperCase() + local.substring(1);
        }
      }
      photoUrl ??= fallbackAuthUser.photoURL;
    }

    final profile = RatingUserBriefProfile(
      userId: cleanUid,
      name: name.isNotEmpty ? name : 'Pengguna',
      photoUrl: photoUrl,
      photoBase64: photoBase64,
    );
    _userProfileCache[cleanUid] = profile;
    return profile;
  }

  Future<GastropediaItem?> _resolveGastropediaItem(String itemId) async {
    final cleanId = itemId.trim();
    if (cleanId.isEmpty) return null;

    if (_encyclopediaCache.containsKey(cleanId)) {
      return _encyclopediaCache[cleanId];
    }

    final staticItem = GastropediaData.getById(cleanId);
    try {
      final doc = await _db.collection('encyclopedia').doc(cleanId).get();
      if (doc.exists && doc.data() != null) {
        final item = GastropediaItem.fromFirestore(doc);
        _encyclopediaCache[cleanId] = item;
        return item;
      }
    } catch (_) {}

    if (staticItem != null) {
      _encyclopediaCache[cleanId] = staticItem;
    }
    return staticItem;
  }

  Future<Map<String, String>> _resolveDoctorMeta(String doctorId) async {
    final cleanId = doctorId.trim();
    if (cleanId.isEmpty) return const {};

    if (_doctorCache.containsKey(cleanId)) {
      return _doctorCache[cleanId]!;
    }

    try {
      final doc = await _db.collection('doctors').doc(cleanId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final meta = <String, String>{
          'name': (data['name'] ?? '').toString().trim(),
          'specialty': (data['specialty'] ?? '').toString().trim(),
          'photoUrl': (data['photoUrl'] ?? '').toString().trim(),
        };
        _doctorCache[cleanId] = meta;
        return meta;
      }
    } catch (_) {}

    return const {};
  }
}
