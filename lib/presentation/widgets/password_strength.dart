import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// Password Strength Helper
// ═══════════════════════════════════════════════════════════

enum PasswordStrength { none, weak, medium, strong }

class PasswordValidator {
  static bool hasMinLength(String p) => p.length >= 8;
  static bool hasUppercase(String p) => p.contains(RegExp(r'[A-Z]'));
  static bool hasLowercase(String p) => p.contains(RegExp(r'[a-z]'));
  static bool hasDigit(String p) => p.contains(RegExp(r'[0-9]'));
  static bool hasSpecialChar(String p) =>
      p.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"|,.<>/?\\`~]'));
  static bool hasNoSpaces(String p) => !p.contains(' ');

  static const _commonPasswords = {
    'password',
    '12345678',
    '123456789',
    '1234567890',
    'qwerty123',
    'abc12345',
    'password1',
    'iloveyou',
    'admin123',
    'welcome1',
    'monkey123',
    'dragon12',
    'master12',
    'letmein1',
    'football1',
  };

  static bool isCommon(String p) => _commonPasswords.contains(p.toLowerCase());

  static int score(String p) {
    if (p.isEmpty) return 0;
    var s = 0;
    if (hasMinLength(p)) s++;
    if (hasUppercase(p)) s++;
    if (hasLowercase(p)) s++;
    if (hasDigit(p)) s++;
    if (hasSpecialChar(p)) s++;
    if (p.length >= 12) s++;
    if (isCommon(p)) s = (s - 2).clamp(0, 6);
    return s;
  }

  static PasswordStrength strength(String p) {
    if (p.isEmpty) return PasswordStrength.none;
    final s = score(p);
    if (s <= 2) return PasswordStrength.weak;
    if (s <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  static String? validate(String? p) {
    if (p == null || p.isEmpty) return 'Campo requerido';
    if (!hasMinLength(p)) return 'Mínimo 8 caracteres';
    if (!hasUppercase(p)) return 'Debe contener al menos una mayúscula';
    if (!hasLowercase(p)) return 'Debe contener al menos una minúscula';
    if (!hasDigit(p)) return 'Debe contener al menos un número';
    if (!hasSpecialChar(p)) {
      return 'Debe contener al menos un carácter especial (!@#\$%...)';
    }
    if (!hasNoSpaces(p)) return 'No debe contener espacios';
    if (isCommon(p)) return 'Esta contraseña es muy común, elige otra';
    return null;
  }
}

// ═══════════════════════════════════════════════════════════
// Password Strength Bar Widget
// ═══════════════════════════════════════════════════════════

class PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  const PasswordStrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    final (label, color, fraction) = switch (strength) {
      PasswordStrength.none => ('', Colors.grey, 0.0),
      PasswordStrength.weak => ('Débil', Colors.red, 0.33),
      PasswordStrength.medium => ('Medio', Colors.orange, 0.66),
      PasswordStrength.strong => ('Fuerte', Colors.green, 1.0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Seguridad: $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Password Requirements Checklist Widget
// ═══════════════════════════════════════════════════════════

class PasswordRequirements extends StatelessWidget {
  final String password;
  const PasswordRequirements({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reqItem(
          'Mínimo 8 caracteres',
          PasswordValidator.hasMinLength(password),
        ),
        _reqItem(
          'Al menos una mayúscula (A-Z)',
          PasswordValidator.hasUppercase(password),
        ),
        _reqItem(
          'Al menos una minúscula (a-z)',
          PasswordValidator.hasLowercase(password),
        ),
        _reqItem(
          'Al menos un número (0-9)',
          PasswordValidator.hasDigit(password),
        ),
        _reqItem(
          'Al menos un carácter especial (!@#\$%...)',
          PasswordValidator.hasSpecialChar(password),
        ),
        _reqItem('Sin espacios', PasswordValidator.hasNoSpaces(password)),
      ],
    );
  }

  Widget _reqItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: met ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
