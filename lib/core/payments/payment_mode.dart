/// How the salary is paid in a month.
enum PaymentMode {
  /// One payment for the whole month.
  onePayment,

  /// One payment for the 1st-15th and one for the 16th-end of the month.
  twoPayments,
}
