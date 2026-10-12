import 'package:flutter/widgets.dart';
import 'package:money_scribe/features/transactions/presentation/transaction_form_screen.dart';

/// TX-5: the form for the transaction [id], to change or delete it.
class EditTransactionScreen extends StatelessWidget {
  const new({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) => TransactionFormScreen(id: id);
}
