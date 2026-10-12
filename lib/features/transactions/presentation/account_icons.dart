import 'package:flutter/material.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';

/// The icon of an account.
IconData accountIcon(AccountKind kind) {
  return switch (kind) {
    AccountKind.card => Icons.credit_card,
    AccountKind.cash => Icons.payments_outlined,
    AccountKind.other => Icons.account_balance_wallet_outlined,
  };
}
