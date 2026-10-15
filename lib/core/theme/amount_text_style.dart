import 'package:flutter/painting.dart';

extension AmountTextStyle on TextStyle {
  /// Fixed-width figures, so amounts line up in columns. Use it for every
  /// amount.
  TextStyle get amount {
    return copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
