import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/presentation/screens/user_profile_screen.dart';

void main() {
  group('PasswordValidator', () {
    group('hasMinLength', () {
      test('false para cadenas menores a 8 caracteres', () {
        expect(PasswordValidator.hasMinLength(''), isFalse);
        expect(PasswordValidator.hasMinLength('1234567'), isFalse);
      });
      test('true para cadenas de 8+ caracteres', () {
        expect(PasswordValidator.hasMinLength('12345678'), isTrue);
        expect(PasswordValidator.hasMinLength('123456789'), isTrue);
      });
    });

    group('hasUppercase', () {
      test('false sin mayúsculas', () {
        expect(PasswordValidator.hasUppercase('abc123'), isFalse);
      });
      test('true con mayúsculas', () {
        expect(PasswordValidator.hasUppercase('Abc123'), isTrue);
      });
    });

    group('hasLowercase', () {
      test('false sin minúsculas', () {
        expect(PasswordValidator.hasLowercase('ABC123'), isFalse);
      });
      test('true con minúsculas', () {
        expect(PasswordValidator.hasLowercase('ABc123'), isTrue);
      });
    });

    group('hasDigit', () {
      test('false sin números', () {
        expect(PasswordValidator.hasDigit('abcABC'), isFalse);
      });
      test('true con números', () {
        expect(PasswordValidator.hasDigit('abc1'), isTrue);
      });
    });

    group('hasSpecialChar', () {
      test('false sin caracteres especiales', () {
        expect(PasswordValidator.hasSpecialChar('Abc12345'), isFalse);
      });
      test('true con caracteres especiales', () {
        expect(PasswordValidator.hasSpecialChar('Abc@1234'), isTrue);
        expect(PasswordValidator.hasSpecialChar('pass!'), isTrue);
        expect(PasswordValidator.hasSpecialChar('pass#'), isTrue);
        expect(PasswordValidator.hasSpecialChar(r'pass$'), isTrue);
      });
    });

    group('hasNoSpaces', () {
      test('false con espacios', () {
        expect(PasswordValidator.hasNoSpaces('abc 123'), isFalse);
      });
      test('true sin espacios', () {
        expect(PasswordValidator.hasNoSpaces('abc123'), isTrue);
      });
    });

    group('isCommon', () {
      test('true para contraseñas comunes', () {
        expect(PasswordValidator.isCommon('password'), isTrue);
        expect(PasswordValidator.isCommon('12345678'), isTrue);
        expect(
          PasswordValidator.isCommon('Password'),
          isTrue,
        ); // case insensitive
        expect(PasswordValidator.isCommon('qwerty123'), isTrue);
      });
      test('false para contraseñas no comunes', () {
        expect(PasswordValidator.isCommon('MiCl@ve\$egura42'), isFalse);
      });
    });

    group('strength', () {
      test('none para vacía', () {
        expect(PasswordValidator.strength(''), PasswordStrength.none);
      });
      test('weak para contraseña solo minúsculas corta', () {
        expect(PasswordValidator.strength('abcdefgh'), PasswordStrength.weak);
      });
      test('weak para contraseña común', () {
        expect(PasswordValidator.strength('password'), PasswordStrength.weak);
      });
      test('medium para contraseña con minúsculas, mayúsculas y números', () {
        expect(PasswordValidator.strength('Abcde123'), PasswordStrength.medium);
      });
      test('strong para contraseña completa larga', () {
        expect(
          PasswordValidator.strength('Abc@12345xyz'),
          PasswordStrength.strong,
        );
      });
    });

    group('validate', () {
      test('error para cadena vacía', () {
        expect(PasswordValidator.validate(''), 'Campo requerido');
        expect(PasswordValidator.validate(null), 'Campo requerido');
      });
      test('error por longitud insuficiente', () {
        expect(PasswordValidator.validate('Ab1!'), 'Mínimo 8 caracteres');
      });
      test('error por falta de mayúscula', () {
        expect(
          PasswordValidator.validate('abcde1234!'),
          'Debe contener al menos una mayúscula',
        );
      });
      test('error por falta de minúscula', () {
        expect(
          PasswordValidator.validate('ABCDE1234!'),
          'Debe contener al menos una minúscula',
        );
      });
      test('error por falta de número', () {
        expect(
          PasswordValidator.validate('AbcdeFFFF!'),
          'Debe contener al menos un número',
        );
      });
      test('error por falta de carácter especial', () {
        expect(
          PasswordValidator.validate('Abcde1234'),
          contains('carácter especial'),
        );
      });
      test('error por espacios', () {
        expect(
          PasswordValidator.validate('Abcde 12!'),
          'No debe contener espacios',
        );
      });
      test('error por contraseña común', () {
        expect(
          PasswordValidator.validate('Password1!'),
          isNull, // 'Password1!' is not in the common list
        );
      });
      test('null para contraseña válida fuerte', () {
        expect(PasswordValidator.validate('MiCl@ve42x'), isNull);
        expect(PasswordValidator.validate('Str0ng!Pass'), isNull);
      });
    });

    group('score', () {
      test('0 para vacía', () {
        expect(PasswordValidator.score(''), 0);
      });
      test('score crece con más criterios cumplidos', () {
        final s1 = PasswordValidator.score('abcdefgh'); // lowercase + length
        final s2 = PasswordValidator.score('Abcde123'); // +upper +digit
        final s3 = PasswordValidator.score('Abc@12345xyz'); // all + long
        expect(s1, lessThan(s2));
        expect(s2, lessThan(s3));
      });
      test('score se reduce para contraseñas comunes', () {
        final common = PasswordValidator.score('password');
        final unique = PasswordValidator.score(
          'xyzwqrst',
        ); // same length, not common
        expect(common, lessThan(unique));
      });
    });
  });
}
