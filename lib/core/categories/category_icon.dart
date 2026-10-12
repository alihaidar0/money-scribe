/// The picture of a category. The screens map each to an icon.
///
/// It lives in `core/` because the transactions, the reports and the category
/// list of the Settings all show it.
enum CategoryIcon {
  groceries,
  dining,
  transport,
  housing,
  utilities,
  health,
  entertainment,
  shopping,
  education,
  travel,
  gifts,
  subscriptions,
  scholarship,
  other;

  /// The pictures a person can choose for a category they make, in the order
  /// the picker shows them. The others belong to the built-in categories.
  static const List<CategoryIcon> choices = [
    gifts,
    health,
    entertainment,
    shopping,
    education,
    travel,
    subscriptions,
    other,
  ];
}
