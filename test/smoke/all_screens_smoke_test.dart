import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/presentation/screens/dashboard_screen.dart';
import 'package:stockia/presentation/screens/product_form_screen.dart';
import 'package:stockia/presentation/screens/product_list_screen.dart';
import 'package:stockia/presentation/screens/inventory_movements_screen.dart';
import 'package:stockia/presentation/screens/stock_alerts_screen.dart';
import 'package:stockia/presentation/screens/user_profile_screen.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/test_helpers.dart';
import '../mocks/test_fixtures.dart';

void main() {
  // ═══════════════════════════════════════════════════════════
  // Smoke – DashboardScreen
  // ═══════════════════════════════════════════════════════════
  group('DashboardScreen – Smoke Tests', () {
    late MockAuthRepository mockAuth;
    late MockProductRepository mockProducts;
    late MockInventoryMovementRepository mockMovements;
    late MockStockAlertRepository mockAlerts;

    setUp(() {
      mockAuth = MockAuthRepository();
      mockProducts = MockProductRepository();
      mockMovements = MockInventoryMovementRepository();
      mockAlerts = MockStockAlertRepository();
    });

    Widget buildDashboard() {
      return testProviderScope(
        authRepo: mockAuth,
        productRepo: mockProducts,
        movementRepo: mockMovements,
        alertRepo: mockAlerts,
        currentUser: testUser,
        products: [testProduct1, testProduct2],
        alerts: [testAlert],
        child: const MaterialApp(home: DashboardScreen()),
      );
    }

    testWidgets('se renderiza sin errores', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('muestra AppBar con título', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('StockIA - Dashboard'), findsOneWidget);
    });

    testWidgets('muestra icono de logout', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('muestra card de usuario', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('muestra 3 métricas', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('Productos'), findsOneWidget);
      expect(find.text('Stock Bajo'), findsOneWidget);
      expect(find.text('Alertas'), findsOneWidget);
    });

    testWidgets('muestra accesos rápidos', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('Accesos rápidos'), findsOneWidget);
      expect(find.text('Nuevo Producto'), findsOneWidget);
      expect(find.text('Movimientos'), findsOneWidget);
    });

    testWidgets('muestra sección Inventario', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('Inventario'), findsOneWidget);
    });

    testWidgets('muestra botón Actualizar', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('Actualizar'), findsOneWidget);
    });

    testWidgets('muestra DataTable con productos', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('muestra filtro SegmentedButton', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Bajo'), findsWidgets);
      expect(find.text('OK'), findsWidgets);
    });

    testWidgets('iconos de métricas correctos', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsWidgets);
      expect(find.byIcon(Icons.notification_important), findsOneWidget);
    });

    testWidgets('iconos de accesos rápidos correctos', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_box), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Smoke – ProductFormScreen
  // ═══════════════════════════════════════════════════════════
  group('ProductFormScreen – Smoke Tests', () {
    Widget buildForm({bool editing = false}) {
      return testProviderScope(
        currentUser: testUser,
        products: editing ? [testProduct1] : [],
        child: MaterialApp(
          home: ProductFormScreen(product: editing ? testProduct1 : null),
        ),
      );
    }

    testWidgets('se renderiza sin errores (crear)', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(find.byType(ProductFormScreen), findsOneWidget);
    });

    testWidgets('se renderiza sin errores (editar)', (tester) async {
      await tester.pumpWidget(buildForm(editing: true));
      await tester.pumpAndSettle();
      expect(find.byType(ProductFormScreen), findsOneWidget);
    });

    testWidgets('tiene campo Nombre del producto', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        findsOneWidget,
      );
    });

    testWidgets('tiene campo Categoría (no ID de Categoría)', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Categoría'), findsOneWidget);
      // Verify old label is NOT present
      expect(
        find.widgetWithText(TextFormField, 'ID de Categoría'),
        findsNothing,
      );
    });

    testWidgets('tiene campo Precio ingreso', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        findsOneWidget,
      );
    });

    testWidgets('tiene campo Precio venta', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Precio venta'),
        findsOneWidget,
      );
    });

    testWidgets('tiene campo Stock actual', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Stock actual'),
        findsOneWidget,
      );
    });

    testWidgets('tiene campo Stock mínimo', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        findsOneWidget,
      );
    });

    testWidgets('botón Crear Producto visible (modo crear)', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(find.text('Crear Producto'), findsOneWidget);
    });

    testWidgets('botón Actualizar visible (modo editar)', (tester) async {
      await tester.pumpWidget(buildForm(editing: true));
      await tester.pumpAndSettle();
      expect(find.text('Actualizar'), findsOneWidget);
    });

    testWidgets('icono eliminar visible (modo editar)', (tester) async {
      await tester.pumpWidget(buildForm(editing: true));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('icono eliminar NO visible (modo crear)', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('iconos de campos correctos', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.label), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.byIcon(Icons.inventory), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Smoke – InventoryMovementsScreen
  // ═══════════════════════════════════════════════════════════
  group('InventoryMovementsScreen – Smoke Tests', () {
    Widget buildMovements({bool empty = true}) {
      return testProviderScope(
        currentUser: testUser,
        products: [testProduct1],
        movements: empty ? [] : [testMovementIn, testMovementOut],
        child: const MaterialApp(home: InventoryMovementsScreen()),
      );
    }

    testWidgets('se renderiza sin errores', (tester) async {
      await tester.pumpWidget(buildMovements());
      await tester.pumpAndSettle();
      expect(find.byType(InventoryMovementsScreen), findsOneWidget);
    });

    testWidgets('muestra título', (tester) async {
      await tester.pumpWidget(buildMovements());
      await tester.pumpAndSettle();
      expect(find.text('Movimientos de Inventario'), findsOneWidget);
    });

    testWidgets('muestra FAB', (tester) async {
      await tester.pumpWidget(buildMovements());
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('mensaje vacío cuando no hay movimientos', (tester) async {
      await tester.pumpWidget(buildMovements());
      await tester.pumpAndSettle();
      expect(find.text('No hay movimientos'), findsOneWidget);
    });

    testWidgets('muestra movimientos cuando existen', (tester) async {
      await tester.pumpWidget(buildMovements(empty: false));
      await tester.pumpAndSettle();
      expect(find.text('Ingreso'), findsOneWidget);
      expect(find.text('Salida'), findsOneWidget);
    });

    testWidgets('movimiento tipo Ingreso tiene icono verde', (tester) async {
      await tester.pumpWidget(buildMovements(empty: false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('movimiento tipo Salida tiene icono rojo', (tester) async {
      await tester.pumpWidget(buildMovements(empty: false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Smoke – StockAlertsScreen
  // ═══════════════════════════════════════════════════════════
  group('StockAlertsScreen – Smoke Tests', () {
    Widget buildAlerts({bool empty = true}) {
      return testProviderScope(
        currentUser: testUser,
        alerts: empty ? [] : [testAlert],
        child: const MaterialApp(home: StockAlertsScreen()),
      );
    }

    testWidgets('se renderiza sin errores', (tester) async {
      await tester.pumpWidget(buildAlerts());
      await tester.pumpAndSettle();
      expect(find.byType(StockAlertsScreen), findsOneWidget);
    });

    testWidgets('muestra título', (tester) async {
      await tester.pumpWidget(buildAlerts());
      await tester.pumpAndSettle();
      expect(find.text('Alertas de Stock'), findsOneWidget);
    });

    testWidgets('sin alertas muestra check verde', (tester) async {
      await tester.pumpWidget(buildAlerts());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('con alertas muestra icono warning', (tester) async {
      await tester.pumpWidget(buildAlerts(empty: false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('con alertas muestra botón Resolver', (tester) async {
      await tester.pumpWidget(buildAlerts(empty: false));
      await tester.pumpAndSettle();
      expect(find.text('Resolver'), findsOneWidget);
    });

    testWidgets('muestra info de stock en alerta', (tester) async {
      await tester.pumpWidget(buildAlerts(empty: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('Stock actual: 5'), findsOneWidget);
      expect(find.textContaining('Mínimo: 10'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Smoke – ProductListScreen
  // ═══════════════════════════════════════════════════════════
  group('ProductListScreen – Smoke Tests', () {
    Widget buildList({bool empty = true}) {
      return testProviderScope(
        currentUser: testUser,
        products: empty ? [] : [testProduct1, testProduct2],
        child: const MaterialApp(home: ProductListScreen()),
      );
    }

    testWidgets('se renderiza sin errores', (tester) async {
      await tester.pumpWidget(buildList());
      await tester.pumpAndSettle();
      expect(find.byType(ProductListScreen), findsOneWidget);
    });

    testWidgets('muestra título Productos', (tester) async {
      await tester.pumpWidget(buildList());
      await tester.pumpAndSettle();
      expect(find.text('Productos'), findsOneWidget);
    });

    testWidgets('mensaje vacío cuando no hay productos', (tester) async {
      await tester.pumpWidget(buildList());
      await tester.pumpAndSettle();
      expect(find.text('No hay productos'), findsOneWidget);
    });

    testWidgets('muestra productos en lista', (tester) async {
      await tester.pumpWidget(buildList(empty: false));
      await tester.pumpAndSettle();
      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
    });

    testWidgets('muestra ícono de inventario por producto', (tester) async {
      await tester.pumpWidget(buildList(empty: false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.inventory), findsNWidgets(2));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Smoke – UserProfileScreen
  // ═══════════════════════════════════════════════════════════
  group('UserProfileScreen – Smoke Tests', () {
    Widget buildProfile() {
      return testProviderScope(
        currentUser: testUser,
        tenant: testTenant,
        child: const MaterialApp(home: UserProfileScreen()),
      );
    }

    testWidgets('se renderiza sin errores', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();
      expect(find.byType(UserProfileScreen), findsOneWidget);
    });

    testWidgets('muestra título Mi Cuenta', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();
      expect(find.text('Mi Cuenta'), findsOneWidget);
    });

    testWidgets('muestra menú lateral con opciones', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Seguridad'), findsOneWidget);
      expect(find.text('Suscripción'), findsOneWidget);
      expect(find.text('Cerrar Sesión'), findsOneWidget);
    });

    testWidgets('sección General visible por defecto', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();
      expect(find.text('Información General'), findsOneWidget);
    });

    testWidgets('botón Editar presente en sección General', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsOneWidget);
    });
  });
}
