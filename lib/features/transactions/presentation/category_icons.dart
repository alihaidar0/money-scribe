import 'package:flutter/material.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// The icon of a category.
IconData categoryIcon(CategoryIcon icon) {
  return switch (icon) {
    CategoryIcon.groceries => Icons.shopping_basket_outlined,
    CategoryIcon.dining => Icons.restaurant_outlined,
    CategoryIcon.transport => Icons.directions_bus_outlined,
    CategoryIcon.housing => Icons.home_outlined,
    CategoryIcon.utilities => Icons.bolt_outlined,
    CategoryIcon.scholarship => Icons.school_outlined,
    CategoryIcon.other => Icons.category_outlined,
  };
}

/// The icon of an account.
IconData accountIcon(AccountKind kind) {
  return switch (kind) {
    AccountKind.card => Icons.credit_card,
    AccountKind.cash => Icons.payments_outlined,
  };
}
