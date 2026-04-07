import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/utils/string_normalizer.dart';

void main() {
  group('normalizeForComparison', () {
    test('ignora mayúsculas y minúsculas', () {
      expect(
        normalizeForComparison('Arroz Diana'),
        normalizeForComparison('arroz diana'),
      );
    });

    test('ignora espacios', () {
      expect(
        normalizeForComparison('ArrozDiana'),
        normalizeForComparison('Arroz Diana'),
      );
    });

    test('ignora combinaciones de espacios y mayúsculas', () {
      expect(
        normalizeForComparison('arrozDiana'),
        normalizeForComparison('Arroz Diana'),
      );
    });

    test('ignora múltiples espacios', () {
      expect(
        normalizeForComparison('Arroz   Diana'),
        normalizeForComparison('ArrozDiana'),
      );
    });

    test('ignora acentos', () {
      expect(normalizeForComparison('café'), normalizeForComparison('cafe'));
    });

    test('ignora acentos, espacios y mayúsculas combinados', () {
      expect(
        normalizeForComparison('Café Latte'),
        normalizeForComparison('cafelatte'),
      );
    });

    test('diferencia productos distintos', () {
      expect(
        normalizeForComparison('Arroz Diana') ==
            normalizeForComparison('Arroz Roa'),
        isFalse,
      );
    });

    test('string vacío', () {
      expect(normalizeForComparison(''), '');
    });

    test('ñ se mantiene como ñ', () {
      expect(normalizeForComparison('Año'), normalizeForComparison('año'));
    });
  });
}
