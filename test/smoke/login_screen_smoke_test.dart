import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/presentation/screens/login_screen.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/test_helpers.dart';

void main() {
  group('LoginScreen – Smoke Tests', () {
    late MockAuthRepository mockAuth;

    setUp(() {
      mockAuth = MockAuthRepository();
    });

    Widget buildLoginScreen() {
      return testProviderScope(
        authRepo: mockAuth,
        child: const MaterialApp(home: LoginScreen()),
      );
    }

    testWidgets('se renderiza sin errores', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('muestra logo de StockIA', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('muestra subtítulo', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    });

    testWidgets('tiene campo de email', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    });

    testWidgets('tiene campo de contraseña', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
    });

    testWidgets('tiene botón Iniciar sesión', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('tiene botón de Google', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('tiene botón de Microsoft', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.text('Microsoft'), findsOneWidget);
    });

    testWidgets('NO muestra botón de Apple', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('tiene link a registro', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.text('¿No tienes cuenta? Regístrate aquí'), findsOneWidget);
    });

    testWidgets('muestra separador O continúa con', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.text('O continúa con'), findsOneWidget);
    });

    testWidgets('validación email vacío muestra error', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu email'), findsOneWidget);
    });

    testWidgets('validación contraseña vacía muestra error', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@test.com',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('validación email inválido muestra error', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'notanemail',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        '123456',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Email no válido'), findsOneWidget);
    });

    testWidgets('validación contraseña corta muestra error', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        '123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });
  });
}
