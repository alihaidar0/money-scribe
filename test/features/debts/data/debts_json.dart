/// A repayment as the server sends it.
Map<String, Object?> repaymentJson({
  String id = '0198f2c1-0000-7000-8000-0000000000a1',
  String amount = '40.00',
  String date = '2026-10-12',
  int version = 1,
}) {
  return {
    'id': id,
    'amount': amount,
    'date': date,
    'version': version,
    'created_at': '2026-10-12T10:00:00Z',
    'updated_at': '2026-10-12T10:00:00Z',
  };
}

/// A debt as the server sends it: lent, 100.00 USD, 40.00 repaid.
Map<String, Object?> debtJson({
  String id = '0198f2c0-4e5a-7d12-a3c4-6b7e8f9a0c1d',
  String direction = 'lent',
  String person = 'Sam',
  String amount = '100.00',
  String currency = 'USD',
  String startDate = '2026-10-01',
  String? dueDate = '2026-10-31',
  String note = 'Lunch money',
  List<Map<String, Object?>>? repayments,
  String? repaid,
  String? remaining,
  String status = 'open',
  int version = 1,
}) {
  return {
    'id': id,
    'direction': direction,
    'person': person,
    'amount': amount,
    'currency': currency,
    'start_date': startDate,
    'due_date': dueDate,
    'note': note,
    'repaid': repaid ?? '40.00',
    'remaining': remaining ?? '60.00',
    'status': status,
    'repayments': repayments ?? [repaymentJson()],
    'version': version,
    'created_at': '2026-10-01T09:00:00Z',
    'updated_at': '2026-10-12T10:00:00Z',
  };
}
