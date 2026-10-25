/// Tells the server which language and time zone the app uses now, so the
/// emails and the reminders of the account are in the language the person
/// reads. Sign-in sends them too; this keeps them current afterwards.
abstract interface class AccountLocaleRepository {
  /// Sends the language and the time zone of the app now, when they differ
  /// from what the server holds. Does nothing while nobody is signed in. Can
  /// throw a `DataException` when the server cannot be reached or fails.
  Future<void> sync();
}
