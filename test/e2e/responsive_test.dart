import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/presentation/screens/login_screen.dart';
import 'package:stockia/presentation/screens/register_screen.dart';
import 'package:stockia/presentation/screens/dashboard_screen.dart';
import 'package:stockia/presentation/screens/product_list_screen.dart';
import 'package:stockia/presentation/screens/product_form_screen.dart';
import 'package:stockia/presentation/screens/inventory_movements_screen.dart';
import 'package:stockia/presentation/screens/stock_alerts_screen.dart';
import 'package:stockia/presentation/screens/user_profile_screen.dart';
import '../mocks/test_fixtures.dart';
import '../mocks/test_helpers.dart';

// ═══════════════════════════════════════════════════════════
// Tamaños de pantalla a probar
// ═══════════════════════════════════════════════════════════
const _sizes = {
  'mobile_small': Size(320, 568), // iPhone SE
  'mobile_medium': Size(375, 812), // iPhone X
  'mobile_large': Size(414, 896), // iPhone 11 Pro Max
  'tablet_portrait': Size(768, 1024), // iPad portrait
  'tablet_landscape': Size(1024, 768), // iPad landscape
  'desktop': Size(1440, 900), // Desktop
  'desktop_wide': Size(1920, 1080), // Full HD
};

/// Renderiza [child] con el tamaño dado y verifica que no haya overflow.
Future<void> _testNoOverflow(
  WidgetTester tester,
  Widget child,
  Size size,
  String label,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
  addTearDown(() => tester.view.resetDevicePixelRatio());

  // Track overflow errors
  final overflowErrors = <FlutterErrorDetails>[];
  final originalHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed') ||
        details.toString().contains('OVERFLOW')) {
      overflowErrors.add(details);
    } else {
      originalHandler?.call(details);
    }
  };

  await tester.pumpWidget(child);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  FlutterError.onError = originalHandler;

  expect(
    overflowErrors,
    isEmpty,
    reason: '$label: overflow en tamaño ${size.width}x${size.height}',
  );
}

void main() {
  // ═══════════════════════════════════════════════════
  // LOGIN SCREEN
  // ═══════════════════════════════════════════════════
  group('Responsive: LoginScreen', () {
    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key}', (tester) async {
        final widget = testProviderScope(
          child: const MaterialApp(home: LoginScreen()),
        );
        await _testNoOverflow(tester, widget, entry.value, 'LoginScreen');
      });
    }

    testWidgets('mobile: layout es columna vertical', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        testProviderScope(child: const MaterialApp(home: LoginScreen())),
      );
      await tester.pumpAndSettle();

      // En mobile no debe haber Row como layout principal (split layout)
      // Debe haber logo + form en columna
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('desktop: layout es split (dos paneles)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        testProviderScope(child: const MaterialApp(home: LoginScreen())),
      );
      await tester.pumpAndSettle();

      // En desktop debe mostrar el texto del panel izquierdo
      expect(
        find.text('Gestiona tu inventario de forma inteligente'),
        findsOneWidget,
      );
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════
  // REGISTER SCREEN
  // ═══════════════════════════════════════════════════
  group('Responsive: RegisterScreen', () {
    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key}', (tester) async {
        final widget = testProviderScope(
          child: const MaterialApp(home: RegisterScreen()),
        );
        await _testNoOverflow(tester, widget, entry.value, 'RegisterScreen');
      });
    }

    testWidgets('mobile: formulario tiene scroll vertical', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        testProviderScope(child: const MaterialApp(home: RegisterScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.text('Datos de la empresa'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════
  // DASHBOARD SCREEN
  // ═══════════════════════════════════════════════════
  group('Responsive: DashboardScreen', () {
    Widget buildDashboard() {
      return testProviderScope(
        currentUser: testUser,
        tenant: testTenant,
        products: [testProduct1, testProduct2],
        movements: [testMovementIn],
        alerts: [testAlert],
        child: const MaterialApp(home: DashboardScreen()),
      );
    }

    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key}', (tester) async {
        await _testNoOverflow(
          tester,
          buildDashboard(),
          entry.value,
          'DashboardScreen',
        );
      });
    }

    testWidgets('mobile: métricas se muestran correctamente', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Total productos'), findsWidgets);
    });

    testWidgets('desktop: tabla de inventario visible', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Inventario'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════
  // PRODUCT LIST SCREEN
  // ═══════════════════════════════════════════════════
  group('Responsive: ProductListScreen', () {
    Widget buildProductList() {
      return testProviderScope(
        currentUser: testUser,
        tenant: testTenant,
        products: [testProduct1, testProduct2],
        child: const MaterialApp(home: ProductListScreen()),
      );
    }

    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key}', (tester) async {
        await _testNoOverflow(
          tester,
          buildProductList(),
          entry.value,
          'ProductListScreen',
        );
      });
    }
  });

  // ═══════════════════════════════════════════════════
  // PRODUCT FORM SCREEN
  // ═══════════════════════════════════════════════════
  group('Responsive: ProductFormScreen', () {
    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key} (nuevo)', (tester) async {
        final widget = testProviderScope(
          currentUser: testUser,
          tenant: testTenant,
          products: [],
          child: const MaterialApp(home: ProductFormScreen()),
        );
        await _testNoOverflow(tester, widget, entry.value, 'ProductFormScreen');
      });
    }

    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key} (editar)', (tester) async {
        final widget = testProviderScope(
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          child: MaterialApp(home: ProductFormScreen(product: testProduct1)),
        );
        await _testNoOverflow(
          tester,
          widget,
          entry.value,
          'ProductFormScreen edit',
        );
      });
    }
  });

  // ═══════════════════════════════════════════════════
  // INVENTORY MOVEMENTS SCREEN
  // ═══════════════════════════════════════════════════
  group('Responsive: InventoryMovementsScreen', () {
    Widget buildMovements() {
      return testProviderScope(
        currentUser: testUser,
        tenant: testTenant,
        products: [testProduct1, testProduct2],
        movements: [testMovementIn, testMovementOut, testMovementAdjustment],
        child: const MaterialApp(home: InventoryMovementsScreen()),
      );
    }

    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key}', (tester) async {
        await _testNoOverflow(
          tester,
          buildMovements(),
          entry.value,
          'InventoryMovementsScreen',
        );
      });
    }
  });

  // ═══════════════════════════════════════════════════
  // STOCK ALERTS SCREEN
  // ═══════════════════════════════════════════════════
  group('Responsive: StockAlertsScreen', () {
    Widget buildAlerts() {
      return testProviderScope(
        currentUser: testUser,
        tenant: testTenant,
        alerts: [testAlert],
        child: const MaterialApp(home: StockAlertsScreen()),
      );
    }

    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key}', (tester) async {
        await _testNoOverflow(
          tester,
          buildAlerts(),
          entry.value,
          'StockAlertsScreen',
        );
      });
    }
  });

  // ═══════════════════════════════════════════════════
  // USER PROFILE SCREEN
  // ═══════════════════════════════════════════════════
  group('Responsive: UserProfileScreen', () {
    Widget buildProfile() {
      return testProviderScope(
        currentUser: testUser,
        tenant: testTenant,
        child: const MaterialApp(home: UserProfileScreen()),
      );
    }

    for (final entry in _sizes.entries) {
      testWidgets('sin overflow en ${entry.key}', (tester) async {
        await _testNoOverflow(
          tester,
          buildProfile(),
          entry.value,
          'UserProfileScreen',
        );
      });
    }

    testWidgets('mobile: menú y contenido legibles', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      // Debe haber elementos del menú visibles
      expect(find.text('General'), findsWidgets);
      // Debe mostrar el contenido de la sección General
      expect(find.text('Información General'), findsOneWidget);
    });

    testWidgets('desktop: menú lateral y contenido lado a lado', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      expect(find.text('General'), findsWidgets);
      expect(find.text('Seguridad'), findsOneWidget);
      expect(find.text('Información General'), findsOneWidget);
    });
  });
}
