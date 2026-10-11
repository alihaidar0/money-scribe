import 'package:flutter/material.dart';

/// One money meaning: the strong colour for amount text, its on-colour for
/// text on a filled shape, and the soft container pair for icon circles and
/// badges (`docs/DESIGN.md`, section 2.1).
@immutable
class MoneyColor {
  const new({
    required this.color,
    required this.onColor,
    required this.container,
    required this.onContainer,
  });

  final Color color;
  final Color onColor;
  final Color container;
  final Color onContainer;

  MoneyColor lerpTo(MoneyColor other, double t) {
    return MoneyColor(
      color: Color.lerp(color, other.color, t)!,
      onColor: Color.lerp(onColor, other.onColor, t)!,
      container: Color.lerp(container, other.container, t)!,
      onContainer: Color.lerp(onContainer, other.onContainer, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MoneyColor &&
        other.color == color &&
        other.onColor == onColor &&
        other.container == container &&
        other.onContainer == onContainer;
  }

  @override
  int get hashCode => Object.hash(color, onColor, container, onContainer);
}

/// The colours that carry money meaning, as a theme extension. Read them with
/// `context.moneyColors`. Meaning is never carried by colour alone: pair each
/// colour with its sign, label or icon.
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  const new({
    required this.income,
    required this.expense,
    required this.borrowed,
    required this.lent,
    required this.overdue,
  });

  static const light = MoneyColors(
    income: MoneyColor(
      color: Color(0xFF2A7851),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFDCF0E0),
      onContainer: Color(0xFF003920),
    ),
    expense: MoneyColor(
      color: Color(0xFF6A2735),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFFFE5E7),
      onContainer: Color(0xFF591928),
    ),
    borrowed: MoneyColor(
      color: Color(0xFF544687),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFEFE7FE),
      onContainer: Color(0xFF342565),
    ),
    lent: MoneyColor(
      color: Color(0xFF00696A),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFD8F0EF),
      onContainer: Color(0xFF003737),
    ),
    overdue: MoneyColor(
      color: Color(0xFF834416),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFFFE6D9),
      onContainer: Color(0xFF522300),
    ),
  );

  static const dark = MoneyColors(
    income: MoneyColor(
      color: Color(0xFF8FDCAD),
      onColor: Color(0xFF00341D),
      container: Color(0xFF2C3D32),
      onContainer: Color(0xFFD4E7D7),
    ),
    expense: MoneyColor(
      color: Color(0xFFE18695),
      onColor: Color(0xFF531524),
      container: Color(0xFF4B3336),
      onContainer: Color(0xFFFFDADD),
    ),
    borrowed: MoneyColor(
      color: Color(0xFFC7B7FF),
      onColor: Color(0xFF302060),
      container: Color(0xFF3B3748),
      onContainer: Color(0xFFE7DFF5),
    ),
    lent: MoneyColor(
      color: Color(0xFF78DCDD),
      onColor: Color(0xFF003232),
      container: Color(0xFF283D3D),
      onContainer: Color(0xFFD0E7E7),
    ),
    overdue: MoneyColor(
      color: Color(0xFFF7A26C),
      onColor: Color(0xFF4B2000),
      container: Color(0xFF4B3427),
      onContainer: Color(0xFFFFDBC8),
    ),
  );

  final MoneyColor income;
  final MoneyColor expense;
  final MoneyColor borrowed;
  final MoneyColor lent;
  final MoneyColor overdue;

  @override
  MoneyColors copyWith({
    MoneyColor? income,
    MoneyColor? expense,
    MoneyColor? borrowed,
    MoneyColor? lent,
    MoneyColor? overdue,
  }) {
    return MoneyColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      borrowed: borrowed ?? this.borrowed,
      lent: lent ?? this.lent,
      overdue: overdue ?? this.overdue,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MoneyColors &&
        other.income == income &&
        other.expense == expense &&
        other.borrowed == borrowed &&
        other.lent == lent &&
        other.overdue == overdue;
  }

  @override
  int get hashCode => Object.hash(income, expense, borrowed, lent, overdue);

  @override
  MoneyColors lerp(MoneyColors? other, double t) {
    if (other == null) return this;
    return MoneyColors(
      income: income.lerpTo(other.income, t),
      expense: expense.lerpTo(other.expense, t),
      borrowed: borrowed.lerpTo(other.borrowed, t),
      lent: lent.lerpTo(other.lent, t),
      overdue: overdue.lerpTo(other.overdue, t),
    );
  }
}

extension MoneyColorsContext on BuildContext {
  /// The money colours of the current theme.
  MoneyColors get moneyColors => Theme.of(this).extension<MoneyColors>()!;
}
