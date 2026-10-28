import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/categories/category_icon.dart';

/// The icon of a category.
IconData categoryIcon(CategoryIcon icon) {
  return switch (icon) {
    CategoryIcon.groceries => LucideIcons.shoppingBasket,
    CategoryIcon.dining => LucideIcons.utensils,
    CategoryIcon.transport => LucideIcons.bus,
    CategoryIcon.housing => LucideIcons.house,
    CategoryIcon.utilities => LucideIcons.zap,
    CategoryIcon.health => LucideIcons.heartPulse,
    CategoryIcon.entertainment => LucideIcons.clapperboard,
    CategoryIcon.shopping => LucideIcons.shoppingBag,
    CategoryIcon.education => LucideIcons.graduationCap,
    CategoryIcon.travel => LucideIcons.plane,
    CategoryIcon.gifts => LucideIcons.gift,
    CategoryIcon.subscriptions => LucideIcons.refreshCw,
    CategoryIcon.scholarship => LucideIcons.award,
    CategoryIcon.other => LucideIcons.shapes,
  };
}
