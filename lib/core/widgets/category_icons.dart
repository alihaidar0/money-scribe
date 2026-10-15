import 'package:flutter/material.dart';
import 'package:money_scribe/core/categories/category_icon.dart';

/// The icon of a category.
IconData categoryIcon(CategoryIcon icon) {
  return switch (icon) {
    CategoryIcon.groceries => Icons.shopping_basket_outlined,
    CategoryIcon.dining => Icons.restaurant_outlined,
    CategoryIcon.transport => Icons.directions_bus_outlined,
    CategoryIcon.housing => Icons.home_outlined,
    CategoryIcon.utilities => Icons.bolt_outlined,
    CategoryIcon.health => Icons.health_and_safety_outlined,
    CategoryIcon.entertainment => Icons.movie_outlined,
    CategoryIcon.shopping => Icons.shopping_bag_outlined,
    CategoryIcon.education => Icons.school_outlined,
    CategoryIcon.travel => Icons.flight_outlined,
    CategoryIcon.gifts => Icons.redeem_outlined,
    CategoryIcon.subscriptions => Icons.autorenew,
    CategoryIcon.scholarship => Icons.workspace_premium_outlined,
    CategoryIcon.other => Icons.category_outlined,
  };
}
