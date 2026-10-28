import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';

/// The icon of an account.
IconData accountIcon(AccountKind kind) {
  return switch (kind) {
    AccountKind.card => LucideIcons.creditCard,
    AccountKind.cash => LucideIcons.banknote,
    AccountKind.other => LucideIcons.wallet,
  };
}
