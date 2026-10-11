/// Keeps [text] in its own left-to-right order inside right-to-left text, as
/// for an email address inside an Arabic sentence.
String isolateLeftToRight(String text) {
  const leftToRightIsolate = 0x2066;
  const popDirectionalIsolate = 0x2069;
  return '${String.fromCharCode(leftToRightIsolate)}$text'
      '${String.fromCharCode(popDirectionalIsolate)}';
}
