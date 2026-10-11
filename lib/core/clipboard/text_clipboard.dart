/// Copies text to the system clipboard. An interface so that Blocs stay free
/// of platform code and tests can record what was copied.
abstract interface class TextClipboard {
  Future<void> copy(String text);
}
