/// One block of the Overview as the server sends it: the pay of 1,000.00,
/// 100.00 of recurring income, 50.00 of income transactions, 300.00 of fixed
/// costs, 120.50 of purchases, 40.00 of repayments received and 15.00 made.
Map<String, Object?> overviewBlockJson({
  String salary = '1000.00',
  String recurringIncome = '100.00',
  String incomeTransactions = '50.00',
  String fixedCosts = '300.00',
  String purchases = '120.50',
  String received = '40.00',
  String made = '15.00',
  String balance = '754.50',
}) {
  return {
    'salary': salary,
    'recurring_income': recurringIncome,
    'income_transactions': incomeTransactions,
    'fixed_costs': fixedCosts,
    'purchases': purchases,
    'debt_repayments_received': received,
    'debt_repayments_made': made,
    'balance': balance,
  };
}

/// The Overview of a month as the server sends it.
Map<String, Object?> overviewJson({
  String month = '2026-10',
  String currency = 'USD',
  bool hasData = true,
  List<String>? currencies,
  Map<String, Object?>? total,
  Map<String, Object?>? firstPart,
  Map<String, Object?>? secondPart,
}) {
  return {
    'month': month,
    'currency': currency,
    'has_data': hasData,
    'currencies': currencies ?? [currency],
    'total': total ?? overviewBlockJson(),
    'first_part': firstPart,
    'second_part': secondPart,
  };
}

/// One category of the spending as the server sends it.
Map<String, Object?> categorySpendJson({
  String id = '0198f2a0-0000-7000-8000-000000000001',
  String? key = 'groceries',
  String name = 'Groceries',
  String icon = 'groceries',
  String amount = '80.00',
}) {
  return {
    'category_id': id,
    'category_key': key,
    'name': name,
    'icon': icon,
    'amount': amount,
  };
}

/// One part of a month report as the server sends it.
Map<String, Object?> reportSliceJson({
  String incomeTransactions = '50.00',
  String purchases = '120.50',
  List<Map<String, Object?>>? categories,
}) {
  return {
    'income_transactions': incomeTransactions,
    'purchases': purchases,
    'categories': categories ?? [categorySpendJson()],
  };
}

/// The month report as the server sends it.
Map<String, Object?> monthReportJson({
  String month = '2026-10',
  String currency = 'USD',
  List<String>? currencies,
  String incomeTransactions = '50.00',
  String purchases = '120.50',
  List<Map<String, Object?>>? categories,
  Map<String, Object?>? firstPart,
  Map<String, Object?>? secondPart,
}) {
  return {
    'month': month,
    'currency': currency,
    'has_data': true,
    'currencies': currencies ?? [currency],
    'income_transactions': incomeTransactions,
    'purchases': purchases,
    'categories':
        categories ??
        [
          categorySpendJson(),
          categorySpendJson(
            id: '0198f2a0-0000-7000-8000-000000000002',
            key: null,
            name: 'Pets',
            icon: 'gifts',
            amount: '40.50',
          ),
        ],
    'first_part': firstPart,
    'second_part': secondPart,
  };
}

/// One debt of the debts report as the server sends it.
Map<String, Object?> debtLineJson({
  String id = '0198f2c0-4e5a-7d12-a3c4-6b7e8f9a0c1d',
  String person = 'Sam',
  String direction = 'lent',
  String remaining = '60.00',
  String status = 'open',
  String? dueDate = '2026-10-31',
}) {
  return {
    'id': id,
    'person': person,
    'direction': direction,
    'remaining': remaining,
    'status': status,
    'due_date': dueDate,
  };
}

/// One currency of the debts report.
Map<String, Object?> currencyDebtsJson({
  String currency = 'USD',
  String owedToYou = '60.00',
  String youOwe = '0.00',
  List<Map<String, Object?>>? overdue,
  List<Map<String, Object?>>? open,
}) {
  return {
    'currency': currency,
    'owed_to_you': owedToYou,
    'you_owe': youOwe,
    'overdue': overdue ?? [],
    'open': open ?? [debtLineJson()],
  };
}

/// The debts report as the server sends it.
Map<String, Object?> debtsReportJson(List<Map<String, Object?>> byCurrency) {
  return {'has_data': byCurrency.isNotEmpty, 'by_currency': byCurrency};
}
