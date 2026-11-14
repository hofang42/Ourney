/// Vietnamese mobile number -> E.164 (`+84912345678`), or null when the input
/// is not 9-10 digits after the leading 0 / +84 (Figma `submitPhone`).
String? toE164Vietnam(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('84')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);
  if (!RegExp(r'^\d{9,10}$').hasMatch(digits)) return null;
  return '+84$digits';
}

/// `+84 912 345 678` for display.
String formatPhoneForDisplay(String e164) {
  final d = e164.startsWith('+84') ? e164.substring(3) : e164;
  if (d.length < 7) return e164;
  return '+84 ${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
}
