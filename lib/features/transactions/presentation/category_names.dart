import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// The names of categories in the language of the app.
extension CategoryNames on AppLocalizations {
  /// The name to show for [category]. The server sends only a key for a
  /// built-in category, so its name comes from the app's own strings; a
  /// category the person made shows the name they typed. A key this version
  /// of the app does not know shows the name the server sent.
  String categoryName(TransactionCategory category) {
    return switch (category.key) {
      'groceries' => categoryNameGroceries,
      'dining' => categoryNameDining,
      'transport' => categoryNameTransport,
      'housing' => categoryNameHousing,
      'utilities' => categoryNameUtilities,
      'scholarship' => categoryNameScholarship,
      'other' => categoryNameOther,
      _ => category.name,
    };
  }

  /// The names a category the person makes cannot take, lower case: the
  /// name of every built-in category in this language and the one the server
  /// knows (the key and the English name), because the server only knows the
  /// English ones and the person reads the others.
  Set<String> reservedCategoryNames(Iterable<TransactionCategory> categories) {
    return {
      for (final category in categories)
        if (!category.isCustom) ...{
          categoryName(category).toLowerCase(),
          category.name.toLowerCase(),
          if (category.key != null) category.key!.toLowerCase(),
        },
    };
  }
}
