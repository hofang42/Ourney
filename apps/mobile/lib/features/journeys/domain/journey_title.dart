/// Whether [title] already states a duration, so UI callers omit their count.
bool titleStatesLength(String title) => _length.hasMatch(title);

final _length = RegExp(
  r'(?<![\p{L}\p{N}])\d+\s*-?\s*(ngày|ngay|đêm|dem|tuần|tuan|tháng|thang|days?|nights?|weeks?|months?|n\d*đ|n\d*d|d\d*n)(?![\p{L}\p{N}])',
  caseSensitive: false,
  unicode: true,
);

/// Keeps each number with the following word when a title wraps.
String keepNumberWithUnit(String title) => title.replaceAllMapped(
  RegExp(r'(\d)[ \t]+(?=\p{L})', unicode: true),
  (match) => '${match[1]}\u00A0',
);
