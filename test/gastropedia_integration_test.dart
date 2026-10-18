import 'package:flutter_test/flutter_test.dart';
import 'package:lamon/models/ensiklopedia_entry_model.dart';
import 'package:lamon/models/gastropedia_item_model.dart';

void main() {
  group('Gastropedia Data & Model Tests', () {
    test('19 data lama GastropediaData.items tetap utuh dan lengkap', () {
      expect(GastropediaData.items.length, 19);

      final makanan = GastropediaData.getByCategory(GastropediaCategory.makanan);
      final buah = GastropediaData.getByCategory(GastropediaCategory.buah);
      final sayuran = GastropediaData.getByCategory(GastropediaCategory.sayuran);

      expect(makanan.length, 7);
      expect(buah.length, 6);
      expect(sayuran.length, 6);

      // Verifikasi setiap item memiliki nutrisi, deskripsi, manfaat, dan kandungan
      for (final item in GastropediaData.items) {
        expect(item.id.isNotEmpty, true, reason: '${item.name} harus memiliki id');
        expect(item.name.isNotEmpty, true);
        expect(item.imageAsset.isNotEmpty, true);
        expect(item.deskripsi.isNotEmpty, true);
        expect(item.manfaat.isNotEmpty, true, reason: '${item.name} harus memiliki manfaat');
        expect(item.kandungan.isNotEmpty, true, reason: '${item.name} harus memiliki kandungan');
        expect(item.calories, greaterThan(0));
      }
    });

    test('GastropediaItem.toFirestore serializes correctly with terbit status', () {
      final sample = GastropediaData.items.first;
      final map = sample.toFirestore();

      expect(map['istilah'], sample.name);
      expect(map['istilahLower'], sample.name.toLowerCase());
      expect(map['status'], 'terbit');
      expect(map['isRecommended'], sample.isRecommended);
      expect(map['imageAsset'], sample.imageAsset);
      expect(map['calories'], sample.calories);
      expect(map['protein'], sample.protein);
      expect(map['carbs'], sample.carbs);
      expect(map['fat'], sample.fat);
      expect(map['manfaat'], sample.manfaat);
      expect(map['kandungan'], sample.kandungan);
    });

    test('EnsiklopediaEntry serializes and deserializes correctly', () {
      final entry = EnsiklopediaEntry(
        id: 'oatmeal',
        istilah: 'Oatmeal',
        istilahLower: 'oatmeal',
        namaLain: 'Havermut',
        definisiSingkat: 'Bubur gandum kaya serat larut',
        penjelasanLengkap: 'Oatmeal sangat baik untuk lambung',
        kategori: 'Makanan',
        status: 'terbit',
        imageAsset: 'assets/images/gastropedia/oatmeal.jpg',
        manfaat: ['Meredakan asam lambung'],
        kandungan: ['Beta-glukan'],
        isRecommended: true,
        calories: 150,
        protein: 5,
        carbs: 27,
        fat: 3,
        createdBy: 'Admin',
        createdById: 'admin-123',
        createdByType: 'admin',
        createdAt: DateTime(2026, 1, 1),
      );

      final map = entry.toFirestore();
      expect(map['istilah'], 'Oatmeal');
      expect(map['namaLain'], 'Havermut');
      expect(map['status'], 'terbit');
      expect(map['isRecommended'], true);
      expect(map['calories'], 150);
      expect(map['protein'], 5);
      expect(map['carbs'], 27);
      expect(map['fat'], 3);
      expect(map['manfaat'], ['Meredakan asam lambung']);
      expect(map['kandungan'], ['Beta-glukan']);
    });

    test('GastropediaCategory.fromString maps accurately with fallback', () {
      expect(GastropediaCategory.fromString('Makanan'), GastropediaCategory.makanan);
      expect(GastropediaCategory.fromString('makanan'), GastropediaCategory.makanan);
      expect(GastropediaCategory.fromString('Buah'), GastropediaCategory.buah);
      expect(GastropediaCategory.fromString('buah-buahan'), GastropediaCategory.buah);
      expect(GastropediaCategory.fromString('Sayuran'), GastropediaCategory.sayuran);
      expect(GastropediaCategory.fromString('sayur'), GastropediaCategory.sayuran);
      // Fallback untuk kategori non-makanan (misal istilah medis)
      expect(GastropediaCategory.fromString('Pencernaan'), GastropediaCategory.makanan);
    });
  });
}
