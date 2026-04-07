// Test de smoke básico para la aplicación StockIA
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/presentation/screens/login_screen.dart';
import 'mocks/test_helpers.dart';

void main() {
  testWidgets('StockIA app smoke test – LoginScreen se renderiza', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testProviderScope(child: const MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    // Verificar que la app muestra la pantalla de login
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
