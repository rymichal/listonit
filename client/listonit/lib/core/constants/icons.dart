import 'package:flutter/material.dart';

class ListIcons {
  static const Map<String, IconData> shoppingIcons = {
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'store': Icons.store,
    'local_grocery_store': Icons.local_grocery_store,
    'restaurant': Icons.restaurant,
    'fastfood': Icons.fastfood,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'cake': Icons.cake,
    'icecream': Icons.icecream,
    'home': Icons.home,
    'cleaning_services': Icons.cleaning_services,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'checkroom': Icons.checkroom,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center,
    'spa': Icons.spa,
    'build': Icons.build,
    'card_giftcard': Icons.card_giftcard,
  };

  static const List<String> iconNames = [
    'shopping_cart',
    'shopping_bag',
    'store',
    'local_grocery_store',
    'restaurant',
    'fastfood',
    'local_cafe',
    'local_bar',
    'cake',
    'icecream',
    'home',
    'cleaning_services',
    'pets',
    'child_care',
    'checkroom',
    'medical_services',
    'fitness_center',
    'spa',
    'build',
    'card_giftcard',
  ];

  static IconData getIcon(String name) {
    return shoppingIcons[name] ?? Icons.shopping_cart;
  }
}
