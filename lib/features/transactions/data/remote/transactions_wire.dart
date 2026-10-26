import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';
import 'package:money_scribe/features/transactions/domain/transactions_page.dart';

/// Turns what the server sends about accounts, categories and transactions
/// into the types of the app, and back. A value the app does not know yet (a
/// new kind of account, a new icon) is shown as the plainest one, so a newer
/// server never breaks an older app. An answer the app cannot read at all (an
/// unknown currency, an amount that does not fit its currency, an unknown kind
/// of transaction) breaks the contract, so it is a `ServerException`.
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

  static Currency currency(api.CurrencyEnum wire) {
    return Currency.tryFromCode(wire.json ?? '') ??
        (throw const ServerException());
  }

  static api.CurrencyEnum currencyToWire(Currency currency) {
    final wire = api.CurrencyEnum.fromJson(currency.code);
    if (wire == api.CurrencyEnum.$unknown) throw const ServerException();
    return wire;
  }

  static TransactionKind transactionKind(api.KindEnum wire) {
    return switch (wire) {
      api.KindEnum.expense => TransactionKind.expense,
      api.KindEnum.income => TransactionKind.income,
      api.KindEnum.$unknown => throw const ServerException(),
    };
  }

  static api.KindEnum transactionKindToWire(TransactionKind kind) {
    return switch (kind) {
      TransactionKind.expense => api.KindEnum.expense,
      TransactionKind.income => api.KindEnum.income,
    };
  }

  /// A day as a calendar day: midnight of the day, whatever the zone.
  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static Transaction transaction(api.Transaction wire) {
    final currency = TransactionsWire.currency(wire.currency);
    return Transaction(
      id: wire.id,
      amount:
          Money.tryParse(wire.amount, currency) ??
          (throw const ServerException()),
      kind: transactionKind(wire.kind),
      date: day(wire.date),
      categoryId: wire.categoryId,
      accountId: wire.accountId,
      note: wire.note,
      version: wire.version,
    );
  }

  static DayTotal dayTotal(api.DayTotal wire) {
    return DayTotal(
      date: day(wire.date),
      totals: [
        for (final item in wire.totals)
          Money.tryParse(item.total, currency(item.currency)) ??
              (throw const ServerException()),
      ],
    );
  }
}
