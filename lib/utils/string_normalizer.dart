/// Normalizes a string for fuzzy comparison by:
/// 1. Converting to lowercase
/// 2. Removing all whitespace
/// 3. Removing accents/diacritics
String normalizeForComparison(String input) {
  var result = input.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  result = _removeDiacritics(result);
  return result;
}

String _removeDiacritics(String str) {
  const withDiacritics =
      'àáâãäåæçèéêëìíîïðñòóôõöùúûüýÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖÙÚÛÜÝ';
  const withoutDiacritics =
      'aaaaaaaceeeeiiiidnooooouuuuyAAAAAAACEEEEIIIIDNOOOOOUUUUY';

  final buffer = StringBuffer();
  for (final char in str.runes) {
    final c = String.fromCharCode(char);
    final index = withDiacritics.indexOf(c);
    buffer.write(index >= 0 ? withoutDiacritics[index] : c);
  }
  return buffer.toString();
}
