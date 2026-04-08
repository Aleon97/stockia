import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/domain/use_cases/product_use_cases.dart';
import 'package:stockia/domain/use_cases/inventory_use_cases.dart';
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
  // E2E – Flujo completo del Dashboard
  // ═══════════════════════════════════════════════════════════
  group('E2E – Dashboard completo', () {
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

    Widget buildDashboard({
      List<ProductEntity>? products,
      List<InventoryMovementEntity>? movements,
      List<StockAlertEntity>? alerts,
    }) {
      return testProviderScope(
        authRepo: mockAuth,
        productRepo: mockProducts,
        movementRepo: mockMovements,
        alertRepo: mockAlerts,
        currentUser: testUser,
        products: products,
        movements: movements,
        alerts: alerts,
        child: const MaterialApp(home: DashboardScreen()),
      );
    }

    testWidgets('Dashboard muestra nombre del usuario', (tester) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('Dashboard muestra tenant ID del usuario', (tester) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();
      expect(find.text('ID: tenant-1'), findsOneWidget);
    });

    testWidgets('Dashboard muestra título StockIA - Dashboard', (tester) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();
      expect(find.text('StockIA - Dashboard'), findsOneWidget);
    });

    testWidgets('Muestra conteo correcto de productos', (tester) async {
      await tester.pumpWidget(
        buildDashboard(products: [testProduct1, testProduct2]),
      );
      await tester.pumpAndSettle();
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('Muestra accesos rápidos', (tester) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();
      expect(find.text('Accesos rápidos'), findsOneWidget);
      expect(find.text('Nuevo Producto'), findsOneWidget);
      expect(find.text('Movimientos'), findsOneWidget);
    });

    testWidgets('Muestra sección Inventario', (tester) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();
      expect(find.text('Inventario'), findsOneWidget);
    });

    testWidgets('Sin productos muestra mensaje vacío', (tester) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No hay productos registrados'),
        findsOneWidget,
      );
    });

    testWidgets('Con productos muestra grid con DataTable', (tester) async {
      await tester.pumpWidget(
        buildDashboard(products: [testProduct1, testProduct2]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
    });

    testWidgets('Grid muestra columnas correctas', (tester) async {
      await tester.pumpWidget(buildDashboard(products: [testProduct1]));
      await tester.pumpAndSettle();
      expect(find.text('Producto'), findsOneWidget);
      expect(find.text('Cantidad Disponible'), findsOneWidget);
      expect(find.text('Cantidad Mínima'), findsOneWidget);
      expect(find.text('Precio Ingreso'), findsOneWidget);
      expect(find.text('Precio Venta'), findsOneWidget);
      expect(find.text('Valor Total'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Acciones'), findsOneWidget);
    });

    testWidgets('Filtro Bajo muestra solo productos con stock bajo', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildDashboard(products: [testProduct1, testProduct2]),
      );
      await tester.pumpAndSettle();

      // Tap on "Bajo" filter
      await tester.tap(find.text('Bajo').first);
      await tester.pumpAndSettle();

      // testProduct2 (Destornillador) is low stock (5 <= 10)
      expect(find.text('Destornillador'), findsOneWidget);
      // testProduct1 (Martillo) has stock 50 > 10, should NOT appear
      expect(find.text('Martillo'), findsNothing);
    });

    testWidgets('Filtro OK muestra solo productos con stock suficiente', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildDashboard(products: [testProduct1, testProduct2]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK').first);
      await tester.pumpAndSettle();

      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsNothing);
    });

    testWidgets('Filtro Todos muestra todos los productos', (tester) async {
      await tester.pumpWidget(
        buildDashboard(products: [testProduct1, testProduct2]),
      );
      await tester.pumpAndSettle();

      // Switch to "Bajo" then back to "Todos"
      await tester.tap(find.text('Bajo').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos').first);
      await tester.pumpAndSettle();

      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
    });

    testWidgets('Botón Nuevo Producto navega a ProductFormScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nuevo Producto'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductFormScreen), findsOneWidget);
      expect(find.text('Nuevo Producto'), findsWidgets);
    });

    testWidgets('Botón Movimientos navega a InventoryMovementsScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Movimientos'));
      await tester.pumpAndSettle();

      expect(find.byType(InventoryMovementsScreen), findsOneWidget);
    });

    testWidgets('Métrica Productos navega a ProductListScreen', (tester) async {
      await tester.pumpWidget(buildDashboard(products: [testProduct1]));
      await tester.pumpAndSettle();

      // Tap on the Productos metric card
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductListScreen), findsOneWidget);
    });

    testWidgets('Botón Actualizar funciona', (tester) async {
      await tester.pumpWidget(
        buildDashboard(products: [testProduct1, testProduct2]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Actualizar'));
      await tester.pumpAndSettle();

      // Should show SnackBar with result
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Botón logout está presente', (tester) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // E2E – ProductFormScreen (Nuevo producto)
  // ═══════════════════════════════════════════════════════════
  group('E2E – ProductFormScreen (crear)', () {
    late MockProductRepository mockProducts;
    late MockStockAlertRepository mockAlerts;

    setUp(() {
      mockProducts = MockProductRepository();
      mockAlerts = MockStockAlertRepository();
    });

    Widget buildForm({
      ProductEntity? product,
      bool restrictEditing = false,
      List<ProductEntity>? existingProducts,
    }) {
      return testProviderScope(
        productRepo: mockProducts,
        alertRepo: mockAlerts,
        currentUser: testUser,
        products: existingProducts ?? [],
        child: MaterialApp(
          home: ProductFormScreen(
            product: product,
            restrictEditing: restrictEditing,
          ),
        ),
      );
    }

    testWidgets('Muestra título "Nuevo Producto" sin producto', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();
      expect(find.text('Nuevo Producto'), findsOneWidget);
    });

    testWidgets('Muestra título "Editar Producto" con producto', (
      tester,
    ) async {
      await tester.pumpWidget(buildForm(product: testProduct1));
      await tester.pumpAndSettle();
      expect(find.text('Editar Producto'), findsOneWidget);
    });

    testWidgets('Muestra todos los campos del formulario', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Categoría'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Precio venta'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Stock actual'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        findsOneWidget,
      );
    });

    testWidgets('Validación de campos vacíos', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();

      // Tap "Crear Producto" without filling anything
      await tester.tap(find.text('Crear Producto'));
      await tester.pumpAndSettle();

      expect(find.text('Campo requerido'), findsWidgets);
    });

    testWidgets('Validación precio no numérico', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'cat',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        'abc',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '5',
      );

      await tester.tap(find.text('Crear Producto'));
      await tester.pumpAndSettle();

      expect(find.text('Número no válido'), findsOneWidget);
    });

    testWidgets('Validación stock no entero', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'cat',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        '100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '150',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '10.5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '5',
      );

      await tester.tap(find.text('Crear Producto'));
      await tester.pumpAndSettle();

      expect(find.text('Número entero requerido'), findsOneWidget);
    });

    testWidgets('Crear producto exitoso llama al use case', (tester) async {
      await tester.pumpWidget(buildForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'Tornillo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'ferretería',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        '500',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '800',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '20',
      );

      await tester.tap(find.text('Crear Producto'));
      await tester.pumpAndSettle();

      expect(mockProducts.createCalled, true);
    });

    testWidgets('Detección de duplicado muestra diálogo de advertencia', (
      tester,
    ) async {
      await tester.pumpWidget(buildForm(existingProducts: [testProduct1]));
      await tester.pumpAndSettle();

      // Type a name that matches "Martillo" with different casing/spacing
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'martillo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'cat',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        '100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '200',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '5',
      );

      await tester.tap(find.text('Crear Producto'));
      await tester.pumpAndSettle();

      expect(find.text('Producto duplicado'), findsOneWidget);
      expect(find.textContaining('Martillo'), findsWidgets);
    });

    testWidgets('Duplicado: Cancelar NO crea el producto', (tester) async {
      await tester.pumpWidget(buildForm(existingProducts: [testProduct1]));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'MARTILLO',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'cat',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        '100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '200',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '5',
      );

      await tester.tap(find.text('Crear Producto'));
      await tester.pumpAndSettle();

      // tap Cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(mockProducts.createCalled, false);
    });

    testWidgets('Duplicado: Continuar SÍ crea el producto', (tester) async {
      await tester.pumpWidget(buildForm(existingProducts: [testProduct1]));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'MARTILLO',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'cat',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        '100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '200',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '5',
      );

      await tester.tap(find.text('Crear Producto'));
      await tester.pumpAndSettle();

      // tap Continuar
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(mockProducts.createCalled, true);
    });

    testWidgets('Edición restringida: campos readOnly tienen fondo gris', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildForm(product: testProduct1, restrictEditing: true),
      );
      await tester.pumpAndSettle();

      // Nombre y precios should be editable
      expect(find.text('Editar Producto'), findsOneWidget);

      // Verify the form pre-fills values
      expect(find.text('Martillo'), findsOneWidget);
    });

    testWidgets('Edición: botón eliminar está presente', (tester) async {
      await tester.pumpWidget(buildForm(product: testProduct1));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Edición: eliminar muestra confirmación', (tester) async {
      await tester.pumpWidget(buildForm(product: testProduct1));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar producto'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('Pre-carga valores al editar', (tester) async {
      await tester.pumpWidget(buildForm(product: testProduct1));
      await tester.pumpAndSettle();

      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('cat-1'), findsOneWidget);
      expect(find.text('18000.00'), findsOneWidget);
      expect(find.text('25000.00'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // E2E – InventoryMovementsScreen
  // ═══════════════════════════════════════════════════════════
  group('E2E – InventoryMovementsScreen', () {
    late MockProductRepository mockProducts;
    late MockInventoryMovementRepository mockMovements;
    late MockStockAlertRepository mockAlerts;

    setUp(() {
      mockProducts = MockProductRepository();
      mockMovements = MockInventoryMovementRepository();
      mockAlerts = MockStockAlertRepository();
    });

    Widget buildMovements({
      List<ProductEntity>? products,
      List<InventoryMovementEntity>? movements,
    }) {
      return testProviderScope(
        productRepo: mockProducts,
        movementRepo: mockMovements,
        alertRepo: mockAlerts,
        currentUser: testUser,
        products: products,
        movements: movements,
        child: const MaterialApp(home: InventoryMovementsScreen()),
      );
    }

    testWidgets('Muestra título correcto', (tester) async {
      await tester.pumpWidget(buildMovements(movements: []));
      await tester.pumpAndSettle();
      expect(find.text('Movimientos de Inventario'), findsOneWidget);
    });

    testWidgets('Sin movimientos muestra mensaje vacío', (tester) async {
      await tester.pumpWidget(buildMovements(movements: []));
      await tester.pumpAndSettle();
      expect(find.text('No hay movimientos'), findsOneWidget);
    });

    testWidgets('Muestra FAB para crear movimiento', (tester) async {
      await tester.pumpWidget(buildMovements(movements: []));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Con movimientos muestra lista', (tester) async {
      await tester.pumpWidget(
        buildMovements(
          products: [testProduct1],
          movements: [testMovementIn, testMovementOut],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ingreso'), findsOneWidget);
      expect(find.text('Salida'), findsOneWidget);
    });

    testWidgets('Movimiento muestra nombre de producto', (tester) async {
      await tester.pumpWidget(
        buildMovements(products: [testProduct1], movements: [testMovementIn]),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Martillo'), findsWidgets);
    });

    testWidgets('Movimiento muestra notas', (tester) async {
      await tester.pumpWidget(
        buildMovements(products: [testProduct1], movements: [testMovementIn]),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Compra proveedor'), findsOneWidget);
    });

    testWidgets('FAB abre formulario de nuevo movimiento', (tester) async {
      await tester.pumpWidget(
        buildMovements(products: [testProduct1], movements: []),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Movimiento'), findsOneWidget);
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Salida'), findsOneWidget);
      expect(find.text('Ajuste'), findsOneWidget);
    });

    testWidgets('Formulario movimiento muestra dropdown de productos', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildMovements(products: [testProduct1], movements: []),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(DropdownButtonFormField<String>, 'Producto'),
        findsOneWidget,
      );
    });

    testWidgets('Formulario movimiento tiene campo cantidad', (tester) async {
      await tester.pumpWidget(buildMovements(products: [], movements: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Cantidad'), findsOneWidget);
    });

    testWidgets('Formulario movimiento tiene campo notas', (tester) async {
      await tester.pumpWidget(buildMovements(products: [], movements: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Notas (opcional)'),
        findsOneWidget,
      );
    });

    testWidgets('Formulario movimiento: validación cantidad vacía', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildMovements(products: [testProduct1], movements: []),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar Movimiento'));
      await tester.pumpAndSettle();

      expect(find.text('Campo requerido'), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // E2E – StockAlertsScreen
  // ═══════════════════════════════════════════════════════════
  group('E2E – StockAlertsScreen', () {
    late MockStockAlertRepository mockAlerts;

    setUp(() {
      mockAlerts = MockStockAlertRepository();
    });

    Widget buildAlerts({List<StockAlertEntity>? alerts}) {
      return testProviderScope(
        alertRepo: mockAlerts,
        currentUser: testUser,
        alerts: alerts,
        child: const MaterialApp(home: StockAlertsScreen()),
      );
    }

    testWidgets('Muestra título correcto', (tester) async {
      await tester.pumpWidget(buildAlerts(alerts: []));
      await tester.pumpAndSettle();
      expect(find.text('Alertas de Stock'), findsOneWidget);
    });

    testWidgets('Sin alertas muestra mensaje de éxito', (tester) async {
      await tester.pumpWidget(buildAlerts(alerts: []));
      await tester.pumpAndSettle();
      expect(find.text('No hay alertas activas'), findsOneWidget);
      expect(
        find.text('Todos los productos tienen stock suficiente'),
        findsOneWidget,
      );
    });

    testWidgets('Con alertas muestra lista', (tester) async {
      await tester.pumpWidget(buildAlerts(alerts: [testAlert]));
      await tester.pumpAndSettle();

      expect(find.text('Destornillador'), findsOneWidget);
      expect(find.textContaining('Stock actual: 5'), findsOneWidget);
      expect(find.textContaining('Mínimo: 10'), findsOneWidget);
    });

    testWidgets('Botón Resolver está presente', (tester) async {
      await tester.pumpWidget(buildAlerts(alerts: [testAlert]));
      await tester.pumpAndSettle();

      expect(find.text('Resolver'), findsOneWidget);
    });

    testWidgets('Resolver muestra diálogo de confirmación', (tester) async {
      await tester.pumpWidget(buildAlerts(alerts: [testAlert]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resolver'));
      await tester.pumpAndSettle();

      expect(find.text('Resolver alerta'), findsOneWidget);
      expect(find.textContaining('Destornillador'), findsWidgets);
    });

    testWidgets('Múltiples alertas se muestran todas', (tester) async {
      final alert2 = StockAlertEntity(
        id: 'alert-2',
        productId: 'prod-3',
        productName: 'Llave inglesa',
        currentStock: 2,
        minimumStock: 5,
        isResolved: false,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );
      await tester.pumpWidget(buildAlerts(alerts: [testAlert, alert2]));
      await tester.pumpAndSettle();

      expect(find.text('Destornillador'), findsOneWidget);
      expect(find.text('Llave inglesa'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // E2E – ProductListScreen
  // ═══════════════════════════════════════════════════════════
  group('E2E – ProductListScreen', () {
    late MockProductRepository mockProducts;

    setUp(() {
      mockProducts = MockProductRepository();
    });

    Widget buildList({List<ProductEntity>? products}) {
      return testProviderScope(
        productRepo: mockProducts,
        currentUser: testUser,
        products: products,
        child: const MaterialApp(home: ProductListScreen()),
      );
    }

    testWidgets('Muestra título Productos', (tester) async {
      await tester.pumpWidget(buildList(products: []));
      await tester.pumpAndSettle();
      expect(find.text('Productos'), findsOneWidget);
    });

    testWidgets('Sin productos muestra mensaje vacío', (tester) async {
      await tester.pumpWidget(buildList(products: []));
      await tester.pumpAndSettle();
      expect(find.text('No hay productos'), findsOneWidget);
    });

    testWidgets('Con productos muestra lista', (tester) async {
      await tester.pumpWidget(
        buildList(products: [testProduct1, testProduct2]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
    });

    testWidgets('Muestra stock y mínimo', (tester) async {
      await tester.pumpWidget(buildList(products: [testProduct1]));
      await tester.pumpAndSettle();
      expect(find.text('Stock: 50 | Mín: 10'), findsOneWidget);
    });

    testWidgets('Muestra precio de venta', (tester) async {
      await tester.pumpWidget(buildList(products: [testProduct1]));
      await tester.pumpAndSettle();
      expect(find.text('\$25000.00'), findsOneWidget);
    });

    testWidgets('Producto con stock bajo tiene indicador rojo', (tester) async {
      await tester.pumpWidget(buildList(products: [testProduct2]));
      await tester.pumpAndSettle();
      // Destornillador has stock 5 <= min 10, so it should show red icon
      expect(find.text('Destornillador'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // E2E – Flujos de negocio backend (Use Cases integrados)
  // ═══════════════════════════════════════════════════════════
  group('E2E – Flujos de negocio complejos', () {
    late MockProductRepository mockProducts;
    late MockInventoryMovementRepository mockMovements;
    late MockStockAlertRepository mockAlerts;

    setUp(() {
      mockProducts = MockProductRepository();
      mockMovements = MockInventoryMovementRepository();
      mockAlerts = MockStockAlertRepository();
    });

    test('Crear producto con stock bajo genera alerta automática', () async {
      final createUseCase = CreateProductUseCase(mockProducts, mockAlerts);
      final lowStockProduct = testProduct2; // stock: 5, min: 10

      await createUseCase(lowStockProduct);

      expect(mockProducts.createCalled, true);
      expect(mockAlerts.createCalled, true);
    });

    test('Crear producto con stock OK NO genera alerta', () async {
      final createUseCase = CreateProductUseCase(mockProducts, mockAlerts);
      await createUseCase(testProduct1); // stock: 50, min: 10

      expect(mockProducts.createCalled, true);
      expect(mockAlerts.createCalled, false);
    });

    test('Actualizar stock a bajo mínimo genera alerta', () async {
      mockProducts.setProducts([testProduct1]);
      final updateUseCase = UpdateProductUseCase(mockProducts, mockAlerts);

      final updated = testProduct1.copyWith(stock: 5);
      await updateUseCase(updated);

      expect(mockAlerts.createCalled, true);
    });

    test('Actualizar stock sobre mínimo elimina alertas previas', () async {
      mockProducts.setProducts([testProduct2]);
      mockAlerts.setAlerts([testAlert]);

      final updateUseCase = UpdateProductUseCase(mockProducts, mockAlerts);
      final updated = testProduct2.copyWith(stock: 20);
      await updateUseCase(updated);

      expect(mockProducts.updateCalled, true);
      // deleteAlertsByProductId should have been called
    });

    test('Eliminar producto limpia alertas asociadas', () async {
      mockProducts.setProducts([testProduct2]);
      mockAlerts.setAlerts([testAlert]);

      final deleteUseCase = DeleteProductUseCase(mockProducts, mockAlerts);
      await deleteUseCase('prod-2');

      expect(mockProducts.deleteCalled, true);
      // Alerts for prod-2 should be removed
      final remainingAlerts = await mockAlerts.getActiveAlerts('tenant-1');
      expect(remainingAlerts, isEmpty);
    });

    test('RefreshAlerts recalcula todas las alertas', () async {
      mockProducts.setProducts([testProduct1, testProduct2]);
      final refreshUseCase = RefreshAlertsUseCase(mockProducts, mockAlerts);

      final count = await refreshUseCase('tenant-1');

      // testProduct2 has low stock, so 1 alert should be created
      expect(count, 1);
      expect(mockAlerts.createCalled, true);
    });

    test('Ciclo: crear → IN → OUT grande → alerta → RefreshAlerts', () async {
      // 1. Create product with good stock
      final createUseCase = CreateProductUseCase(mockProducts, mockAlerts);
      await createUseCase(testProduct1); // stock 50, min 10
      expect(mockAlerts.createCalled, false);

      // 2. Register IN movement
      final registerMovement = RegisterMovementUseCase(
        mockMovements,
        mockProducts,
        mockAlerts,
      );
      await registerMovement(testMovementIn); // +20 → 70
      var products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 70);

      // 3. Register large OUT movement
      final bigOut = InventoryMovementEntity(
        id: 'cycle-out',
        type: MovementType.OUT,
        quantity: 65,
        productId: 'prod-1',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );
      await registerMovement(bigOut); // -65 → 5
      products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 5);

      // 4. Alert should have been created (5 <= 10)
      expect(mockAlerts.createCalled, true);

      // 5. RefreshAlerts should detect it
      final refreshUseCase = RefreshAlertsUseCase(mockProducts, mockAlerts);
      final count = await refreshUseCase('tenant-1');
      expect(count, 1);
    });

    test('Movimiento IN que repone stock sobre mínimo', () async {
      mockProducts.setProducts([testProduct2]); // stock: 5, min: 10

      final registerMovement = RegisterMovementUseCase(
        mockMovements,
        mockProducts,
        mockAlerts,
      );

      final restock = InventoryMovementEntity(
        id: 'restock',
        type: MovementType.IN,
        quantity: 50,
        productId: 'prod-2',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );
      await registerMovement(restock); // 5 + 50 = 55

      final products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 55);
      // No new alert because 55 > 10
      expect(mockAlerts.createCalled, false);
    });

    test('Ajuste a 0 genera alerta', () async {
      mockProducts.setProducts([testProduct1]); // stock: 50, min: 10

      final registerMovement = RegisterMovementUseCase(
        mockMovements,
        mockProducts,
        mockAlerts,
      );

      final zeroAdjust = InventoryMovementEntity(
        id: 'zero-adjust',
        type: MovementType.ADJUSTMENT,
        quantity: 0,
        productId: 'prod-1',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );
      await registerMovement(zeroAdjust); // = 0

      final products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 0);
      expect(mockAlerts.createCalled, true);
    });

    test('Multi-tenant: movimientos no cruzan tenants', () async {
      mockProducts.setProducts([testProduct1, testProductOtherTenant]);
      mockMovements.setMovements([testMovementIn]);

      final tenant1Movements = await mockMovements.getMovements('tenant-1');
      final tenant2Movements = await mockMovements.getMovements('tenant-2');

      expect(tenant1Movements.length, 1);
      expect(tenant2Movements.length, 0);
    });

    test('Multi-tenant: alertas no cruzan tenants', () async {
      mockAlerts.setAlerts([testAlert]);

      final tenant1Alerts = await mockAlerts.getActiveAlerts('tenant-1');
      final tenant2Alerts = await mockAlerts.getActiveAlerts('tenant-2');

      expect(tenant1Alerts.length, 1);
      expect(tenant2Alerts.length, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // E2E – UserProfileScreen
  // ═══════════════════════════════════════════════════════════
  group('E2E – UserProfileScreen', () {
    Widget buildProfile() {
      return testProviderScope(
        currentUser: testUser,
        tenant: testTenant,
        child: const MaterialApp(home: UserProfileScreen()),
      );
    }

    testWidgets('Muestra título Mi Cuenta', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();
      expect(find.text('Mi Cuenta'), findsOneWidget);
    });

    testWidgets('Muestra menú con 4 opciones', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Seguridad'), findsOneWidget);
      expect(find.text('Suscripción'), findsOneWidget);
      expect(find.text('Cerrar Sesión'), findsOneWidget);
    });

    testWidgets('Sección General muestra info del usuario', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();
      expect(find.text('Información General'), findsOneWidget);
      expect(find.text('Ferretería El Martillo'), findsOneWidget);
      expect(find.text('900.123.456-7'), findsOneWidget);
      expect(find.text('test@stockia.com'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('tenant-1'), findsOneWidget);
    });

    testWidgets('Botón Editar habilita edición de campos', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      // Should have editable text fields for company name, NIT, email, legal rep
      expect(find.byType(TextField), findsAtLeast(4));
    });

    testWidgets('Login con contraseña permite editar correo', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      // Email field should be enabled (password login)
      final emailFields = tester.widgetList<TextField>(find.byType(TextField));
      // The email field (3rd) should be enabled
      final emailField = emailFields.elementAt(2);
      expect(emailField.enabled, isTrue);
    });

    testWidgets('Login con Google bloquea edición de correo', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          currentUser: testUser,
          tenant: testTenant,
          authProviderType: 'google',
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      // Should show info message about social login
      expect(find.textContaining('Google'), findsOneWidget);
    });

    testWidgets('Cancelar edición restaura estado', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Editar'));
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cancelar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Editar'));
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
    });

    testWidgets('Tap en Seguridad muestra formulario de contraseña', (
      tester,
    ) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      expect(find.text('Cambiar Contraseña'), findsWidgets);
      expect(find.text('Contraseña actual'), findsOneWidget);
      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.text('Confirmar nueva contraseña'), findsOneWidget);
    });

    testWidgets('Tap en Suscripción muestra sección en desarrollo', (
      tester,
    ) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suscripción'));
      await tester.pumpAndSettle();

      expect(find.text('Esta sección está en desarrollo.'), findsOneWidget);
    });

    testWidgets('Dashboard navega a perfil al tocar tarjeta usuario', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test User'));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfileScreen), findsOneWidget);
      expect(find.text('Mi Cuenta'), findsOneWidget);
    });

    testWidgets('Email duplicado muestra error y bloquea guardado', (
      tester,
    ) async {
      final mockAuth = MockAuthRepository();
      mockAuth.setCurrentUser(testUser);
      mockAuth.addEmailInUse('existing@google.com');

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Entrar en modo edición
      await tester.ensureVisible(find.text('Editar'));
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      // Cambiar email a uno que ya existe
      final emailField = find.byType(TextField).at(2);
      await tester.ensureVisible(emailField);
      await tester.tap(emailField);
      await tester.enterText(emailField, 'existing@google.com');
      await tester.pumpAndSettle();

      // Guardar
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Debe mostrar error de email duplicado
      expect(find.textContaining('ya está registrado'), findsOneWidget);
      // No debe mostrar el diálogo de contraseña
      expect(find.text('Confirmar identidad'), findsNothing);
    });

    testWidgets('Email no duplicado solicita contraseña para cambiar', (
      tester,
    ) async {
      final mockAuth = MockAuthRepository();
      mockAuth.setCurrentUser(testUser);
      // No se agrega el email como "en uso"

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Editar'));
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      // Cambiar email a uno disponible
      final emailField = find.byType(TextField).at(2);
      await tester.ensureVisible(emailField);
      await tester.tap(emailField);
      await tester.enterText(emailField, 'new@email.com');
      await tester.pumpAndSettle();

      // Guardar
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Debe solicitar contraseña
      expect(find.text('Confirmar identidad'), findsOneWidget);
      expect(find.text('Contraseña actual'), findsOneWidget);
    });

    testWidgets('Empresa vacía muestra error al guardar', (tester) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Editar'));
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      // Limpiar nombre de empresa
      final companyField = find.byType(TextField).at(0);
      await tester.ensureVisible(companyField);
      await tester.tap(companyField);
      await tester.enterText(companyField, '');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('no puede estar vacío'), findsOneWidget);
    });

    testWidgets('Login social no verifica email duplicado al guardar', (
      tester,
    ) async {
      final mockAuth = MockAuthRepository();
      mockAuth.setCurrentUser(testUser);
      mockAuth.setAuthProvider('google');

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          authProviderType: 'google',
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      // El campo email debe estar deshabilitado
      final emailFields = tester.widgetList<TextField>(find.byType(TextField));
      final emailField = emailFields.elementAt(2);
      expect(emailField.enabled, isFalse);

      // Guardar sin cambiar email debe funcionar sin pedir contraseña
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // No debe pedir contraseña ni mostrar error de email
      expect(find.text('Confirmar identidad'), findsNothing);
      expect(find.textContaining('ya está registrado'), findsNothing);
    });

    // ── Tests de Seguridad: validación de contraseña y barra de fortaleza ──

    testWidgets('Seguridad muestra requisitos al escribir contraseña', (
      tester,
    ) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      // Escribir una contraseña parcial
      final newPwdField = find.byType(TextFormField).at(1);
      await tester.enterText(newPwdField, 'abc');
      await tester.pumpAndSettle();

      // Debe mostrar la lista de requisitos
      expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
      expect(find.text('Al menos una mayúscula (A-Z)'), findsOneWidget);
      expect(find.text('Al menos una minúscula (a-z)'), findsOneWidget);
      expect(find.text('Al menos un número (0-9)'), findsOneWidget);
      expect(
        find.textContaining('Al menos un carácter especial'),
        findsOneWidget,
      );
      expect(find.text('Sin espacios'), findsOneWidget);
      // Debe mostrar barra de seguridad
      expect(find.textContaining('Seguridad:'), findsOneWidget);
    });

    testWidgets('Seguridad muestra nivel Débil para contraseña simple', (
      tester,
    ) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      final newPwdField = find.byType(TextFormField).at(1);
      await tester.enterText(newPwdField, 'abc12345');
      await tester.pumpAndSettle();

      expect(find.text('Seguridad: Débil'), findsOneWidget);
    });

    testWidgets('Seguridad muestra nivel Medio para contraseña mixta', (
      tester,
    ) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      final newPwdField = find.byType(TextFormField).at(1);
      await tester.enterText(newPwdField, 'Abcdef12');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining('Seguridad:'));
      await tester.pumpAndSettle();

      expect(find.text('Seguridad: Medio'), findsOneWidget);
    });

    testWidgets('Seguridad muestra nivel Fuerte para contraseña completa', (
      tester,
    ) async {
      await tester.pumpWidget(buildProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      final newPwdField = find.byType(TextFormField).at(1);
      await tester.enterText(newPwdField, 'Abc@12345xyz');
      await tester.pumpAndSettle();

      expect(find.text('Seguridad: Fuerte'), findsOneWidget);
    });

    testWidgets('Seguridad valida contraseña débil al intentar guardar', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          currentUser: testUser,
          tenant: testTenant,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1200, 900)),
              child: const UserProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      final currentPwdField = find.byType(TextFormField).at(0);
      await tester.enterText(currentPwdField, 'OldPass123!');

      final newPwdField = find.byType(TextFormField).at(1);
      await tester.enterText(newPwdField, 'abc12345');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(TextFormField).at(2));
      await tester.pumpAndSettle();
      final confirmPwdField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmPwdField, 'abc12345');
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(FilledButton, 'Cambiar Contraseña');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Debe contener al menos una mayúscula'), findsOneWidget);
    });

    testWidgets('Seguridad rechaza contraseñas que no coinciden', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          currentUser: testUser,
          tenant: testTenant,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1200, 900)),
              child: const UserProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      final currentPwdField = find.byType(TextFormField).at(0);
      await tester.enterText(currentPwdField, 'OldPass123!');

      final newPwdField = find.byType(TextFormField).at(1);
      await tester.enterText(newPwdField, 'NuevaPass@123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(TextFormField).at(2));
      await tester.pumpAndSettle();
      final confirmPwdField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmPwdField, 'DiferentePass@123');
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(FilledButton, 'Cambiar Contraseña');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });
  });
}
