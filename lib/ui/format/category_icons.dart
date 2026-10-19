import 'package:flutter/material.dart';

/// Icon names are stored as words so the database never holds code points.
class CategoryIcons {
  const CategoryIcons._();

  static const byName = <String, IconData>{
    'groceries': Icons.shopping_basket_outlined,
    'rent': Icons.home_outlined,
    'utilities': Icons.lightbulb_outline,
    'transport': Icons.directions_bus_outlined,
    'phone': Icons.phone_iphone,
    'eatingOut': Icons.restaurant_outlined,
    'health': Icons.medical_services_outlined,
    'household': Icons.chair_outlined,
    'personal': Icons.face_outlined,
    'fun': Icons.celebration_outlined,
    'school': Icons.school_outlined,
    'church': Icons.volunteer_activism_outlined,
    'family': Icons.family_restroom,
    'savings': Icons.savings_outlined,
    'other': Icons.more_horiz,
  };

  static IconData of(String name) => byName[name] ?? Icons.more_horiz;
}
