import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/data/item_catalog.dart';
import 'package:carbon_tracker/models/shopping_item.dart';

void main() {
  group('ItemCatalog content', () {
    test('has at least 25 items total',
        () => expect(ItemCatalog.all.length, greaterThanOrEqualTo(25)));
    test('T-shirt is in clothing at 3 kg (manufacture-only)', () {
      final item = ItemCatalog.all.firstWhere((i) => i.name == 'T-shirt');
      expect(item.category, ShoppingCategory.clothing);
      expect(item.co2KgNew, 3.0);
    });
    test('Smartphone is in electronics at 70 kg', () {
      final item = ItemCatalog.all.firstWhere((i) => i.name == 'Smartphone');
      expect(item.co2KgNew, 70.0);
    });
    test('Laptop is 200 kg', () {
      expect(
          ItemCatalog.all.firstWhere((i) => i.name == 'Laptop').co2KgNew,
          200.0);
    });
  });

  group('ItemCatalog search', () {
    test('exact match: "jeans" finds Jeans', () {
      expect(ItemCatalog.search('jeans').any((i) => i.name == 'Jeans'), isTrue);
    });
    test('synonym: "trainers" finds Shoes', () {
      expect(
          ItemCatalog.search('trainers').any((i) => i.name == 'Shoes'), isTrue);
    });
    test('synonym: "phone" finds Smartphone', () {
      expect(ItemCatalog.search('phone').any((i) => i.name == 'Smartphone'),
          isTrue);
    });
    test('synonym: "telly" finds TV', () {
      expect(ItemCatalog.search('telly').any((i) => i.name == 'TV'), isTrue);
    });
    test('synonym: "jumper" finds Sweater', () {
      expect(
          ItemCatalog.search('jumper').any((i) => i.name == 'Sweater'), isTrue);
    });
    test('empty query returns all items', () {
      expect(ItemCatalog.search('').length, ItemCatalog.all.length);
    });
    test('no match returns empty list', () {
      expect(ItemCatalog.search('zzznomatch'), isEmpty);
    });
  });
}
