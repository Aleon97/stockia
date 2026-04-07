import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/presentation/screens/login_screen.dart';
import 'package:stockia/presentation/screens/register_screen.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/test_helpers.dart';

void main() {
  group('E2E – Flujo de autenticación', () {
    late MockAuthRepository mockAuth;

    setUp(() {
      mockAuth = MockAuthRepository();
    });

    Widget buildApp({Widget? home}) {
      return testProviderScope(
        authRepo: mockAuth,
        child: MaterialApp(home: home ?? const LoginScreen()),
      );
    }

    testWidgets('Login exitoso: formulario → submit → usuario logueado', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@stockia.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        '123456',
      );

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(mockAuth.signInCalled, true);
    });

    testWidgets('Login con error muestra SnackBar', (tester) async {
      mockAuth.shouldThrow = true;
      mockAuth.errorMessage = 'Credenciales inválidas';

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'wrong@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'wrongpass',
      );

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Navegación Login → Registro', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('¿No tienes cuenta? Regístrate aquí'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Crear cuenta'), findsWidgets);
    });

    testWidgets('Social login Google invoca provider correcto', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Google'));
      await tester.pump();

      expect(mockAuth.socialLoginCalled, true);
      expect(mockAuth.lastSocialProvider, SocialAuthProvider.google);
    });

    testWidgets('Social login Microsoft invoca provider correcto', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Microsoft'));
      await tester.pump();

      expect(mockAuth.socialLoginCalled, true);
      expect(mockAuth.lastSocialProvider, SocialAuthProvider.microsoft);
    });
  });

  group('E2E – Flujo de registro', () {
    late MockAuthRepository mockAuth;

    setUp(() {
      mockAuth = MockAuthRepository();
    });

    Widget buildRegister() {
      return testProviderScope(
        authRepo: mockAuth,
        child: const MaterialApp(home: RegisterScreen()),
      );
    }

    testWidgets('Registro completo: todos los campos → submit → éxito', (
      tester,
    ) async {
      await tester.pumpWidget(buildRegister());
      await tester.pumpAndSettle();

      // Llenar nombre empresa
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de la empresa *'),
        'Mi Ferretería',
      );

      // Llenar NIT
      await tester.enterText(
        find.widgetWithText(TextFormField, 'NIT *'),
        '900.123.456-7',
      );

      // Seleccionar tipo de negocio
      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Tipo de negocio *',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ferretería').last);
      await tester.pumpAndSettle();

      // Llenar representante legal
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del representante legal *'),
        'Juan Pérez',
      );

      // Scroll down
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Llenar email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        'test@miferreteria.com',
      );

      // Llenar confirmar email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar correo electrónico *'),
        'test@miferreteria.com',
      );

      // Scroll más
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Llenar contraseña
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña *'),
        'Test@1234',
      );

      // Llenar confirmar contraseña
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
        'Test@1234',
      );

      // Aceptar términos (tap en el Checkbox, no en el texto)
      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }

      // Scroll para ver el botón
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Tap botón registrar
      final buttons = find.widgetWithText(FilledButton, 'Crear cuenta');
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pump();
      }

      expect(mockAuth.signUpCalled, true);
      expect(mockAuth.lastSignUpData?.companyName, 'Mi Ferretería');
      expect(mockAuth.lastSignUpData?.nit, '900.123.456-7');
    });

    testWidgets('Emails no coincidentes muestra error de validación', (
      tester,
    ) async {
      await tester.pumpWidget(buildRegister());
      await tester.pumpAndSettle();

      // Scroll a campos de email
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        'a@b.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar correo electrónico *'),
        'different@b.com',
      );

      // Scroll al botón
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      final buttons = find.widgetWithText(FilledButton, 'Crear cuenta');
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
      }

      // Scroll arriba para ver error
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      expect(find.text('Los correos no coinciden'), findsOneWidget);
    });
  });
}
