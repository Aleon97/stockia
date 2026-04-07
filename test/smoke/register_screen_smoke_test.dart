import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/presentation/screens/register_screen.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/test_helpers.dart';

void main() {
  group('RegisterScreen – Smoke Tests', () {
    late MockAuthRepository mockAuth;

    setUp(() {
      mockAuth = MockAuthRepository();
    });

    Widget buildRegisterScreen() {
      return testProviderScope(
        authRepo: mockAuth,
        child: const MaterialApp(home: RegisterScreen()),
      );
    }

    testWidgets('se renderiza sin errores', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('muestra título Crear cuenta', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(find.text('Crear cuenta'), findsWidgets);
    });

    testWidgets('muestra sección Datos de la empresa', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(find.text('Datos de la empresa'), findsOneWidget);
    });

    testWidgets('tiene campo nombre empresa', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Nombre de la empresa *'),
        findsOneWidget,
      );
    });

    testWidgets('tiene campo NIT', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'NIT *'), findsOneWidget);
    });

    testWidgets('tiene dropdown tipo de negocio', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Tipo de negocio *',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tiene campo representante legal', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Nombre del representante legal *'),
        findsOneWidget,
      );
    });

    testWidgets('tiene campos de email y confirmación', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Confirmar correo electrónico *'),
        findsOneWidget,
      );
    });

    testWidgets('tiene campos de contraseña y confirmación', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Contraseña *'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
        findsOneWidget,
      );
    });

    testWidgets('tiene checkbox de términos y condiciones', (tester) async {
      await tester.pumpWidget(buildRegisterScreen());
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });
  });
}
