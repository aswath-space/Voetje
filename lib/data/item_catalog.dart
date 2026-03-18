import 'package:flutter/material.dart';
import 'package:carbon_tracker/models/shopping_item.dart';

class ItemCatalog {
  static const List<ShoppingItem> clothing = [
    ShoppingItem(name: 'T-shirt', co2KgNew: 3.0, icon: Icons.checkroom_outlined, category: ShoppingCategory.clothing,
        synonyms: ['tshirt', 't shirt', 'shirt']),
    ShoppingItem(name: 'Jeans', co2KgNew: 14.0, icon: Icons.straighten_outlined, category: ShoppingCategory.clothing,
        synonyms: ['denim', 'trousers', 'pants']),
    ShoppingItem(name: 'Dress', co2KgNew: 10.0, icon: Icons.dry_cleaning_outlined, category: ShoppingCategory.clothing),
    ShoppingItem(name: 'Jacket', co2KgNew: 12.0, icon: Icons.layers_outlined, category: ShoppingCategory.clothing,
        synonyms: ['coat', 'anorak']),
    ShoppingItem(name: 'Winter coat', co2KgNew: 20.0, icon: Icons.severe_cold_outlined, category: ShoppingCategory.clothing,
        synonyms: ['coat', 'parka', 'puffer']),
    ShoppingItem(name: 'Sweater', co2KgNew: 12.0, icon: Icons.texture_outlined, category: ShoppingCategory.clothing,
        synonyms: ['jumper', 'pullover', 'knitwear']),
    ShoppingItem(name: 'Shoes', co2KgNew: 10.0, icon: Icons.ice_skating_outlined, category: ShoppingCategory.clothing,
        synonyms: ['trainers', 'sneakers', 'boots', 'heels', 'footwear']),
    ShoppingItem(name: 'Underwear/socks pack', co2KgNew: 2.5, icon: Icons.inventory_2_outlined, category: ShoppingCategory.clothing,
        synonyms: ['socks', 'underwear', 'knickers', 'boxers']),
  ];

  static const List<ShoppingItem> electronics = [
    ShoppingItem(name: 'Smartphone', co2KgNew: 70.0, icon: Icons.smartphone_outlined, category: ShoppingCategory.electronics,
        synonyms: ['phone', 'mobile', 'iphone', 'android']),
    ShoppingItem(name: 'Laptop', co2KgNew: 200.0, icon: Icons.laptop_outlined, category: ShoppingCategory.electronics,
        synonyms: ['notebook', 'macbook', 'computer']),
    ShoppingItem(name: 'Tablet', co2KgNew: 100.0, icon: Icons.tablet_outlined, category: ShoppingCategory.electronics,
        synonyms: ['ipad']),
    ShoppingItem(name: 'TV', co2KgNew: 150.0, icon: Icons.tv_outlined, category: ShoppingCategory.electronics,
        synonyms: ['television', 'telly', 'screen']),
    ShoppingItem(name: 'Gaming console', co2KgNew: 100.0, icon: Icons.sports_esports_outlined, category: ShoppingCategory.electronics,
        synonyms: ['playstation', 'xbox', 'nintendo', 'console', 'ps5']),
    ShoppingItem(name: 'Headphones', co2KgNew: 10.0, icon: Icons.headphones_outlined, category: ShoppingCategory.electronics,
        synonyms: ['earphones', 'earbuds', 'airpods']),
    ShoppingItem(name: 'Small appliance', co2KgNew: 30.0, icon: Icons.electrical_services_outlined, category: ShoppingCategory.electronics,
        synonyms: ['kettle', 'toaster', 'blender', 'microwave', 'hairdryer']),
    ShoppingItem(name: 'Large appliance', co2KgNew: 350.0, icon: Icons.kitchen_outlined, category: ShoppingCategory.electronics,
        synonyms: ['washing machine', 'fridge', 'dishwasher', 'oven', 'freezer']),
  ];

  static const List<ShoppingItem> furniture = [
    ShoppingItem(name: 'Sofa', co2KgNew: 150.0, icon: Icons.chair_outlined, category: ShoppingCategory.furniture,
        synonyms: ['couch', 'settee']),
    ShoppingItem(name: 'Table', co2KgNew: 50.0, icon: Icons.table_restaurant_outlined, category: ShoppingCategory.furniture,
        synonyms: ['desk', 'dining table']),
    ShoppingItem(name: 'Chair', co2KgNew: 40.0, icon: Icons.chair_outlined, category: ShoppingCategory.furniture,
        synonyms: ['office chair', 'armchair']),
    ShoppingItem(name: 'Bed / Mattress', co2KgNew: 100.0, icon: Icons.bed_outlined, category: ShoppingCategory.furniture,
        synonyms: ['mattress', 'bed frame', 'divan']),
    ShoppingItem(name: 'Bookcase / Shelf', co2KgNew: 30.0, icon: Icons.book_outlined, category: ShoppingCategory.furniture,
        synonyms: ['bookshelf', 'shelving', 'ikea']),
  ];

  static const List<ShoppingItem> other = [
    ShoppingItem(name: 'Book', co2KgNew: 1.5, icon: Icons.menu_book_outlined, category: ShoppingCategory.other,
        synonyms: ['novel', 'textbook', 'paperback', 'hardback']),
    ShoppingItem(name: 'Online order / package', co2KgNew: 0.5, icon: Icons.inventory_2_outlined, category: ShoppingCategory.other,
        synonyms: ['amazon', 'delivery', 'parcel', 'package']),
    ShoppingItem(name: 'Toys / games', co2KgNew: 10.0, icon: Icons.toys_outlined, category: ShoppingCategory.other,
        synonyms: ['toy', 'game', 'lego', 'puzzle']),
    ShoppingItem(name: 'Bicycle', co2KgNew: 100.0, icon: Icons.directions_bike_outlined, category: ShoppingCategory.other,
        synonyms: ['bike', 'cycle', 'e-bike', 'ebike']),
  ];

  static List<ShoppingItem> get all => [...clothing, ...electronics, ...furniture, ...other];

  static List<ShoppingItem> byCategory(ShoppingCategory cat) =>
      all.where((i) => i.category == cat).toList();

  static List<ShoppingItem> search(String query) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase().trim();
    return all.where((item) {
      if (item.name.toLowerCase().contains(q)) return true;
      if (item.synonyms.any((s) => s.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }
}
