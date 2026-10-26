import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// Turns what the server sends about accounts and categories into the types
/// of the app, and back. A value the app does not know yet (a new kind of
/// account, a new icon) is shown as the plainest one, so a newer server never
/// breaks an older app.
abstract final class TransactionsWire {
  static Account account(api.Account wire) {
    return Account(
      id: wire.id,
      name: wire.name,
      kind: accountKind(wire.kind),
      version: wire.version,
    );
  }

  static AccountKind accountKind(api.AccountKindEnum wire) {
    return switch (wire) {
      api.AccountKindEnum.card => AccountKind.card,
      api.AccountKindEnum.cash => AccountKind.cash,
      api.AccountKindEnum.other ||
      api.AccountKindEnum.$unknown => AccountKind.other,
    };
  }

  static api.AccountKindEnum accountKindToWire(AccountKind kind) {
    return switch (kind) {
      AccountKind.card => api.AccountKindEnum.card,
      AccountKind.cash => api.AccountKindEnum.cash,
      AccountKind.other => api.AccountKindEnum.other,
    };
  }

  static TransactionCategory category(api.Category wire) {
    return TransactionCategory(
      id: wire.id,
      name: wire.name,
      icon: icon(wire.icon),
      kind: categoryKind(wire.kind),
      isCustom: wire.isCustom,
      key: wire.key,
      version: wire.version,
    );
  }

  static CategoryKind categoryKind(api.CategoryKindEnum wire) {
    return switch (wire) {
      api.CategoryKindEnum.expense => CategoryKind.expense,
      api.CategoryKindEnum.income => CategoryKind.income,
      api.CategoryKindEnum.both ||
      api.CategoryKindEnum.$unknown => CategoryKind.both,
    };
  }

  /// The icon of the slug the server sent; `other` for one the app does not
  /// know.
  static CategoryIcon icon(String slug) {
    for (final icon in CategoryIcon.values) {
      if (icon.name == slug) return icon;
    }
    return CategoryIcon.other;
  }

  /// The icon as the server accepts it for a category the person makes. The
  /// picker offers only [CategoryIcon.choices], which the server knows all.
  static api.IconEnum iconToWire(CategoryIcon icon) {
    return switch (icon) {
      CategoryIcon.gifts => api.IconEnum.gifts,
      CategoryIcon.health => api.IconEnum.health,
      CategoryIcon.entertainment => api.IconEnum.entertainment,
      CategoryIcon.shopping => api.IconEnum.shopping,
      CategoryIcon.education => api.IconEnum.education,
      CategoryIcon.travel => api.IconEnum.travel,
      CategoryIcon.subscriptions => api.IconEnum.subscriptions,
      _ => api.IconEnum.other,
    };
  }
}
