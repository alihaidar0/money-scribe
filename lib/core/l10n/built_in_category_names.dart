import 'package:money_scribe/core/l10n/l10n.dart';

/// The names of the built-in categories in the language of the app.
extension BuiltInCategoryNames on AppLocalizations {
  /// The name to show for a category with the [key] and the [name] the server
  /// sent. The server sends only a key for a built-in category, so its name
  /// comes from the app's own strings; a category the person made (no key)
  /// shows the name they typed. A key this version of the app does not know
  /// shows the name the server sent.
  String builtInCategoryName({required String? key, required String name}) {
    return switch (key) {
      'groceries' => categoryNameGroceries,
      'dining' => categoryNameDining,
      'transport' => categoryNameTransport,
      'housing' => categoryNameHousing,
      'utilities' => categoryNameUtilities,
      'scholarship' => categoryNameScholarship,
      'other' => categoryNameOther,
      _ => name,
    };
  }
}
