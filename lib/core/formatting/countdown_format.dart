/// A number of seconds as minutes and seconds, such as `4:59` or `0:42`, with
/// Western digits in every language.
String formatCountdown(int seconds) {
  final clamped = seconds < 0 ? 0 : seconds;
  final minutes = clamped ~/ 60;
  final rest = (clamped % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}
