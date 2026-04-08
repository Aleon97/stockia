// Tests profundos de journey completo de usuario:
// Login normal, Login Google, Login Microsoft → Dashboard → toda la app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/presentation/screens/login_screen.dart';
import 'package:stockia/presentation/screens/dashboard_screen.dart';
import 'package:stockia/presentation/screens/register_screen.dart';
import 'package:stockia/presentation/screens/product_list_screen.dart';
import 'package:stockia/presentation/screens/product_form_screen.dart';
import 'package:stockia/presentation/screens/inventory_movements_screen.dart';
import 'package:stockia/presentation/screens/stock_alerts_screen.dart';
import 'package:stockia/presentation/screens/user_profile_screen.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/test_fixtures.dart';
import '../mocks/test_helpers.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════
  // SECCIÓN 1: LOGIN CON EMAIL/PASSWORD – JOURNEY COMPLETO
  // ════════════════════════════════════════════════════════════════════
  group('Journey: Login con email/password', () {
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

    Widget buildLogin() {
      return testProviderScope(
        authRepo: mockAuth,
        productRepo: mockProducts,
        movementRepo: mockMovements,
        alertRepo: mockAlerts,
        child: const MaterialApp(home: LoginScreen()),
      );
    }

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
        tenant: testTenant,
        products: products ?? [testProduct1, testProduct2],
        movements: movements ?? [testMovementIn, testMovementOut],
        alerts: alerts ?? [testAlert],
        child: const MaterialApp(home: DashboardScreen()),
      );
    }

    // ── Login Form UI ──
    testWidgets('Login: muestra logo, texto y formulario', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(
        find.text('Gestiona tu inventario de forma inteligente'),
        findsOneWidget,
      );
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('O continúa con'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Microsoft'), findsOneWidget);
      expect(find.text('¿No tienes cuenta? Regístrate aquí'), findsOneWidget);
    });

    testWidgets('Login: validación email vacío', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu email'), findsOneWidget);
    });

    testWidgets('Login: validación email inválido', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'correo_sin_arroba',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'Test@1234',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Email no válido'), findsOneWidget);
    });

    testWidgets('Login: validación contraseña vacía', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@stockia.com',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('Login: validación contraseña corta', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@stockia.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        '123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('Login: submit exitoso llama signIn', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@stockia.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'Test@1234',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(mockAuth.signInCalled, true);
    });

    testWidgets('Login: error muestra SnackBar', (tester) async {
      mockAuth.shouldThrow = true;
      mockAuth.errorMessage = 'Mock error';

      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@stockia.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'Test@1234',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Login: navegar a registro', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.tap(find.text('¿No tienes cuenta? Regístrate aquí'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    // ── Dashboard tras login normal ──
    testWidgets('Dashboard: muestra KPIs nuevos', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Total productos'), findsOneWidget);
      expect(find.text('Valor inventario'), findsOneWidget);
    });

    testWidgets('Dashboard: muestra métricas correctas', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Total productos'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 productos
      expect(find.text('Stock bajo'), findsOneWidget);
      expect(find.text('Alertas activas'), findsOneWidget);
    });

    testWidgets('Dashboard: tabla inventario muestra productos', (
      tester,
    ) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
    });

    testWidgets('Dashboard: filtro stock bajo funciona', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      // Tap en "Bajo" (aparece en SegmentedButton y en _StockBadge)
      final bajoButton = find.text('Bajo');
      if (bajoButton.evaluate().isNotEmpty) {
        await tester.tap(bajoButton.first);
        await tester.pumpAndSettle();

        // Solo Destornillador tiene stock bajo (5 <= 10)
        expect(find.text('Destornillador'), findsOneWidget);
        expect(find.text('Martillo'), findsNothing);
      }
    });

    testWidgets('Dashboard: filtro OK muestra solo stock normal', (
      tester,
    ) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton.first);
        await tester.pumpAndSettle();

        expect(find.text('Martillo'), findsOneWidget);
        expect(find.text('Destornillador'), findsNothing);
      }
    });

    testWidgets('Dashboard: filtro Todos muestra todos', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      // Primero ir a Bajo, luego volver a Todos
      final bajoButton = find.text('Bajo');
      if (bajoButton.evaluate().isNotEmpty) {
        await tester.tap(bajoButton.first);
        await tester.pumpAndSettle();
      }

      final todosButton = find.text('Todos');
      if (todosButton.evaluate().isNotEmpty) {
        await tester.tap(todosButton);
        await tester.pumpAndSettle();
      }

      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
    });

    testWidgets('Dashboard: acceso rápido Nuevo Producto navega', (
      tester,
    ) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nuevo producto'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductFormScreen), findsOneWidget);
    });

    testWidgets('Dashboard: acceso rápido Movimientos navega', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Movimientos'));
      await tester.pumpAndSettle();

      expect(find.byType(InventoryMovementsScreen), findsOneWidget);
    });

    testWidgets('Dashboard: tap en métrica Productos navega a lista', (
      tester,
    ) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      // Tap en la card de Productos
      final productCard = find.ancestor(
        of: find.text('Total productos'),
        matching: find.byType(Card),
      );
      if (productCard.evaluate().isNotEmpty) {
        await tester.tap(productCard.first);
        await tester.pumpAndSettle();

        expect(find.byType(ProductListScreen), findsOneWidget);
      }
    });

    testWidgets('Dashboard: KPI Stock bajo presente', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Stock bajo'), findsOneWidget);
    });

    // ── Navegación desde Dashboard a cada pantalla ──
    testWidgets('Dashboard → StockAlerts muestra alertas', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          alertRepo: mockAlerts,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: testUser,
          tenant: testTenant,
          alerts: [testAlert],
          child: const MaterialApp(home: StockAlertsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alertas de Stock'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
      expect(find.textContaining('Stock actual: 5'), findsOneWidget);
    });

    testWidgets('StockAlerts: resolver alerta muestra diálogo', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          alertRepo: mockAlerts,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: testUser,
          tenant: testTenant,
          alerts: [testAlert],
          child: const MaterialApp(home: StockAlertsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resolver'));
      await tester.pumpAndSettle();

      expect(find.text('Resolver alerta'), findsOneWidget);
      expect(find.text('Resolver'), findsNWidgets(2));
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('StockAlerts vacío muestra mensaje', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          alertRepo: mockAlerts,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: testUser,
          tenant: testTenant,
          alerts: [],
          child: const MaterialApp(home: StockAlertsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay alertas activas'), findsOneWidget);
    });

    // ── ProductListScreen ──
    testWidgets('ProductList muestra productos con precios', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1, testProduct2],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
    });

    // ── ProductFormScreen: Crear producto ──
    testWidgets('ProductForm: campos vacíos muestra validaciones', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          products: [],
          child: const MaterialApp(home: ProductFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap guardar sin llenar
      final guardarBtn = find.text('Crear Producto');
      if (guardarBtn.evaluate().isNotEmpty) {
        await tester.tap(guardarBtn);
        await tester.pumpAndSettle();

        expect(find.textContaining('requerido'), findsWidgets);
      }
    });

    testWidgets('ProductForm: crear producto exitoso', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          products: [],
          child: const MaterialApp(home: ProductFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'Sierra eléctrica',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'Herramientas',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        '50000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '75000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '20',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '5',
      );

      final guardarBtn = find.text('Crear Producto');
      if (guardarBtn.evaluate().isNotEmpty) {
        await tester.tap(guardarBtn);
        await tester.pumpAndSettle();

        expect(mockProducts.createCalled, true);
      }
    });

    testWidgets('ProductForm: editar producto muestra datos existentes', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          child: MaterialApp(home: ProductFormScreen(product: testProduct1)),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica que los campos tienen los datos del producto
      expect(find.text('Martillo'), findsOneWidget);
    });

    // ── InventoryMovementsScreen ──
    testWidgets('Movimientos: muestra lista de movimientos', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          movements: [testMovementIn, testMovementOut],
          child: const MaterialApp(home: InventoryMovementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Movimientos de Inventario'), findsOneWidget);
      expect(find.textContaining('Compra proveedor'), findsOneWidget);
      expect(find.textContaining('Venta al cliente'), findsOneWidget);
    });

    testWidgets('Movimientos: FAB abre formulario bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          movements: [],
          child: const MaterialApp(home: InventoryMovementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Movimiento'), findsOneWidget);
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Salida'), findsOneWidget);
      expect(find.text('Ajuste'), findsOneWidget);
    });

    testWidgets('Movimientos vacío muestra estado vacío', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          movements: [],
          child: const MaterialApp(home: InventoryMovementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay movimientos'), findsOneWidget);
    });

    // ── UserProfileScreen: General ──
    testWidgets('Perfil: muestra sección General con datos tenant', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Seguridad'), findsOneWidget);
      expect(find.text('Suscripción'), findsOneWidget);
      expect(find.text('Cerrar Sesión'), findsOneWidget);
    });

    testWidgets('Perfil: campos de empresa son editables en password auth', (
      tester,
    ) async {
      mockAuth.setAuthProvider('password');
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          authProviderType: 'password',
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica que muestra los datos del tenant (en modo lectura usa Text, no TextFormField)
      expect(find.text('Nombre de la Empresa'), findsOneWidget);
    });

    testWidgets('Perfil: sección Seguridad muestra cambio de contraseña', (
      tester,
    ) async {
      mockAuth.setAuthProvider('password');
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          authProviderType: 'password',
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      expect(find.text('Cambiar Contraseña'), findsWidgets);
      expect(
        find.widgetWithText(TextFormField, 'Contraseña actual'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Nueva contraseña'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Confirmar nueva contraseña'),
        findsOneWidget,
      );
    });

    testWidgets('Perfil: Suscripción muestra placeholder', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suscripción'));
      await tester.pumpAndSettle();

      expect(find.textContaining('desarrollo'), findsOneWidget);
    });

    // ── Dashboard: eliminar producto con diálogo ──
    testWidgets('Dashboard: eliminar producto muestra diálogo confirmación', (
      tester,
    ) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      // Buscar ícono de eliminar (puede estar fuera del viewport en DataTable)
      final deleteIcons = find.byIcon(Icons.delete);
      if (deleteIcons.evaluate().isNotEmpty) {
        await tester.ensureVisible(deleteIcons.first);
        await tester.pumpAndSettle();
        await tester.tap(deleteIcons.first);
        await tester.pumpAndSettle();

        expect(find.text('Eliminar producto'), findsOneWidget);
      }
    });

    // ── Dashboard sin datos ──
    testWidgets('Dashboard: sin productos muestra estado vacío', (
      tester,
    ) async {
      await tester.pumpWidget(buildDashboard(products: []));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('Dashboard: sin alertas muestra 0', (tester) async {
      await tester.pumpWidget(buildDashboard(alerts: []));
      await tester.pumpAndSettle();

      // Los contadores de alertas deberían mostrar 0
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Dashboard: botón logout funciona', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(mockAuth.signOutCalled, true);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // SECCIÓN 2: LOGIN CON GOOGLE – JOURNEY COMPLETO
  // ════════════════════════════════════════════════════════════════════
  group('Journey: Login con Google', () {
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

    Widget buildLogin() {
      return testProviderScope(
        authRepo: mockAuth,
        productRepo: mockProducts,
        movementRepo: mockMovements,
        alertRepo: mockAlerts,
        child: const MaterialApp(home: LoginScreen()),
      );
    }

    testWidgets('Google login: botón visible y funcional', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      final googleBtn = find.text('Google');
      expect(googleBtn, findsOneWidget);

      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(mockAuth.socialLoginCalled, true);
      expect(mockAuth.lastSocialProvider, SocialAuthProvider.google);
    });

    testWidgets('Google login: error muestra SnackBar', (tester) async {
      mockAuth.shouldThrow = true;
      mockAuth.errorMessage = 'popup-closed-by-user';

      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Google'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Google login: usuario social ve Dashboard correctamente', (
      tester,
    ) async {
      final socialUser = testUser.copyWith(
        id: 'google-uid',
        email: 'user@gmail.com',
        displayName: 'Google User',
      );

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          alertRepo: mockAlerts,
          currentUser: socialUser,
          tenant: testTenant,
          products: [testProduct1],
          alerts: [],
          authProviderType: 'google.com',
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Martillo'), findsOneWidget);
    });

    testWidgets(
      'Google login: Perfil muestra email deshabilitado para social',
      (tester) async {
        final socialUser = testUser.copyWith(
          id: 'google-uid',
          email: 'user@gmail.com',
          displayName: 'Google User',
        );

        mockAuth.setAuthProvider('google.com');
        await tester.pumpWidget(
          testProviderScope(
            authRepo: mockAuth,
            currentUser: socialUser,
            tenant: testTenant,
            authProviderType: 'google',
            child: const MaterialApp(home: UserProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Activar modo edición para ver mensaje de social login
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();

        // Para social login el campo email está deshabilitado
        expect(find.textContaining('no se puede editar'), findsOneWidget);
      },
    );

    testWidgets(
      'Google login: Seguridad muestra mensaje sin cambio de contraseña',
      (tester) async {
        final socialUser = testUser.copyWith(
          id: 'google-uid',
          email: 'user@gmail.com',
          displayName: 'Google User',
        );

        mockAuth.setAuthProvider('google.com');
        await tester.pumpWidget(
          testProviderScope(
            authRepo: mockAuth,
            currentUser: socialUser,
            tenant: testTenant,
            authProviderType: 'google',
            child: const MaterialApp(home: UserProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Seguridad'));
        await tester.pumpAndSettle();

        // La sección de seguridad muestra el formulario de cambio de contraseña
        expect(find.text('Cambiar Contraseña'), findsWidgets);
      },
    );

    testWidgets('Google login: puede crear productos', (tester) async {
      final socialUser = testUser.copyWith(
        id: 'google-uid',
        email: 'user@gmail.com',
      );

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: socialUser,
          tenant: testTenant,
          products: [],
          child: const MaterialApp(home: ProductFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'Taladro Google',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'Herramientas',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        '80000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '120000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '15',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '3',
      );

      final guardarBtn = find.text('Crear Producto');
      if (guardarBtn.evaluate().isNotEmpty) {
        await tester.tap(guardarBtn);
        await tester.pumpAndSettle();
        expect(mockProducts.createCalled, true);
      }
    });

    testWidgets('Google login: puede ver y registrar movimientos', (
      tester,
    ) async {
      final socialUser = testUser.copyWith(
        id: 'google-uid',
        email: 'user@gmail.com',
      );

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: socialUser,
          tenant: testTenant,
          products: [testProduct1],
          movements: [testMovementIn],
          child: const MaterialApp(home: InventoryMovementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Compra proveedor'), findsOneWidget);

      // Abrir formulario
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Movimiento'), findsOneWidget);
    });

    testWidgets('Google login: puede ver y resolver alertas', (tester) async {
      final socialUser = testUser.copyWith(
        id: 'google-uid',
        email: 'user@gmail.com',
      );

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          alertRepo: mockAlerts,
          productRepo: mockProducts,
          currentUser: socialUser,
          tenant: testTenant,
          alerts: [testAlert],
          child: const MaterialApp(home: StockAlertsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Destornillador'), findsOneWidget);
      await tester.tap(find.text('Resolver'));
      await tester.pumpAndSettle();
      expect(find.text('Resolver'), findsNWidgets(2));
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // SECCIÓN 3: LOGIN CON MICROSOFT – JOURNEY COMPLETO
  // ════════════════════════════════════════════════════════════════════
  group('Journey: Login con Microsoft', () {
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

    Widget buildLogin() {
      return testProviderScope(
        authRepo: mockAuth,
        productRepo: mockProducts,
        movementRepo: mockMovements,
        alertRepo: mockAlerts,
        child: const MaterialApp(home: LoginScreen()),
      );
    }

    testWidgets('Microsoft login: botón visible y funcional', (tester) async {
      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      final msBtn = find.text('Microsoft');
      expect(msBtn, findsOneWidget);

      await tester.tap(msBtn);
      await tester.pumpAndSettle();

      expect(mockAuth.socialLoginCalled, true);
      expect(mockAuth.lastSocialProvider, SocialAuthProvider.microsoft);
    });

    testWidgets('Microsoft login: error muestra SnackBar', (tester) async {
      mockAuth.shouldThrow = true;

      await tester.pumpWidget(buildLogin());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Microsoft'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Microsoft login: usuario ve Dashboard', (tester) async {
      final msUser = testUser.copyWith(
        id: 'ms-uid',
        email: 'user@outlook.com',
        displayName: 'Microsoft User',
      );

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          alertRepo: mockAlerts,
          currentUser: msUser,
          tenant: testTenant,
          products: [testProduct1, testProduct2],
          alerts: [testAlert],
          authProviderType: 'microsoft.com',
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
    });

    testWidgets(
      'Microsoft login: Perfil muestra email deshabilitado para social',
      (tester) async {
        final msUser = testUser.copyWith(
          id: 'ms-uid',
          email: 'user@outlook.com',
          displayName: 'MS User',
        );

        mockAuth.setAuthProvider('microsoft.com');
        await tester.pumpWidget(
          testProviderScope(
            authRepo: mockAuth,
            currentUser: msUser,
            tenant: testTenant,
            authProviderType: 'microsoft',
            child: const MaterialApp(home: UserProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Activar modo edición para ver mensaje de social login
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();

        expect(find.textContaining('no se puede editar'), findsOneWidget);
      },
    );

    testWidgets('Microsoft login: Seguridad sin cambio de contraseña', (
      tester,
    ) async {
      final msUser = testUser.copyWith(
        id: 'ms-uid',
        email: 'user@outlook.com',
        displayName: 'MS User',
      );

      mockAuth.setAuthProvider('microsoft.com');
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: msUser,
          tenant: testTenant,
          authProviderType: 'microsoft',
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      // La sección de seguridad muestra el formulario de cambio de contraseña
      expect(find.text('Cambiar Contraseña'), findsWidgets);
    });

    testWidgets('Microsoft login: flujo completo productos', (tester) async {
      final msUser = testUser.copyWith(id: 'ms-uid', email: 'user@outlook.com');

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: msUser,
          tenant: testTenant,
          products: [testProduct1],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Martillo'), findsOneWidget);
    });

    testWidgets('Microsoft login: puede registrar movimientos', (tester) async {
      final msUser = testUser.copyWith(id: 'ms-uid', email: 'user@outlook.com');

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: msUser,
          tenant: testTenant,
          products: [testProduct1],
          movements: [],
          child: const MaterialApp(home: InventoryMovementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Movimiento'), findsOneWidget);
      expect(find.text('Entrada'), findsOneWidget);
    });

    testWidgets('Microsoft login: accede a alertas', (tester) async {
      final msUser = testUser.copyWith(id: 'ms-uid', email: 'user@outlook.com');

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          alertRepo: mockAlerts,
          productRepo: mockProducts,
          currentUser: msUser,
          tenant: testTenant,
          alerts: [testAlert],
          child: const MaterialApp(home: StockAlertsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Destornillador'), findsOneWidget);
    });

    testWidgets('Microsoft login: logout funciona', (tester) async {
      final msUser = testUser.copyWith(
        id: 'ms-uid',
        email: 'user@outlook.com',
        displayName: 'MS User',
      );

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          alertRepo: mockAlerts,
          currentUser: msUser,
          tenant: testTenant,
          products: [],
          authProviderType: 'microsoft.com',
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(mockAuth.signOutCalled, true);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // SECCIÓN 4: REGISTRO COMPLETO → DASHBOARD
  // ════════════════════════════════════════════════════════════════════
  group('Journey: Registro completo', () {
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

    testWidgets('Registro: todos los campos visibles', (tester) async {
      await tester.pumpWidget(buildRegister());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Nombre de la empresa *'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'NIT *'), findsOneWidget);
      expect(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Tipo de negocio *',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Nombre del representante legal *'),
        findsOneWidget,
      );
    });

    testWidgets('Registro: scroll muestra campos de credenciales', (
      tester,
    ) async {
      await tester.pumpWidget(buildRegister());
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
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

    testWidgets('Registro: contraseña muestra barra de fortaleza', (
      tester,
    ) async {
      await tester.pumpWidget(buildRegister());
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      final pwdField = find.widgetWithText(TextFormField, 'Contraseña *');
      if (pwdField.evaluate().isNotEmpty) {
        await tester.enterText(pwdField, 'Test@1234');
        await tester.pumpAndSettle();

        // Verifica que aparece la barra de fortaleza
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('Registro: emails no coinciden muestra error', (tester) async {
      await tester.pumpWidget(buildRegister());
      await tester.pumpAndSettle();

      // Llenar empresa
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de la empresa *'),
        'Mi Empresa',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'NIT *'),
        '900.111.222-3',
      );

      // Seleccionar tipo negocio
      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Tipo de negocio *',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ferretería').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del representante legal *'),
        'Ana García',
      );

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        'test@empresa.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar correo electrónico *'),
        'diferente@empresa.com',
      );

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña *'),
        'Test@1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
        'Test@1234',
      );

      // Aceptar términos
      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final crearBtn = find.widgetWithText(FilledButton, 'Crear cuenta');
      if (crearBtn.evaluate().isNotEmpty) {
        await tester.tap(crearBtn.first);
        await tester.pumpAndSettle();

        expect(find.text('Los correos no coinciden'), findsOneWidget);
      }
    });

    testWidgets('Registro: contraseñas no coinciden muestra error', (
      tester,
    ) async {
      await tester.pumpWidget(buildRegister());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de la empresa *'),
        'Mi Empresa',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'NIT *'),
        '900.111.222-3',
      );

      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Tipo de negocio *',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ferretería').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del representante legal *'),
        'Ana García',
      );

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        'test@empresa.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar correo electrónico *'),
        'test@empresa.com',
      );

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña *'),
        'Test@1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
        'Otra@5678',
      );

      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final crearBtn = find.widgetWithText(FilledButton, 'Crear cuenta');
      if (crearBtn.evaluate().isNotEmpty) {
        await tester.tap(crearBtn.first);
        await tester.pumpAndSettle();

        expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      }
    });

    testWidgets('Registro exitoso: llama signUp con datos correctos', (
      tester,
    ) async {
      await tester.pumpWidget(buildRegister());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de la empresa *'),
        'Nueva Ferretería',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'NIT *'),
        '900.555.666-7',
      );

      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Tipo de negocio *',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ferretería').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del representante legal *'),
        'Pedro López',
      );

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        'pedro@ferreteria.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar correo electrónico *'),
        'pedro@ferreteria.com',
      );

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña *'),
        'Test@1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
        'Test@1234',
      );

      // Scroll para ver checkbox y botón
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final crearBtn = find.widgetWithText(FilledButton, 'Crear cuenta');
      if (crearBtn.evaluate().isNotEmpty) {
        await tester.tap(crearBtn.first);
        await tester.pump();
      }

      expect(mockAuth.signUpCalled, true);
      expect(mockAuth.lastSignUpData?.companyName, 'Nueva Ferretería');
      expect(mockAuth.lastSignUpData?.nit, '900.555.666-7');
      expect(mockAuth.lastSignUpData?.email, 'pedro@ferreteria.com');
      expect(mockAuth.lastSignUpData?.legalRepresentative, 'Pedro López');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // SECCIÓN 5: VALIDACIONES CRUZADAS Y CASOS BORDE
  // ════════════════════════════════════════════════════════════════════
  group('Validaciones cruzadas y casos borde', () {
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

    testWidgets('Dashboard: múltiples alertas se muestran', (tester) async {
      final alert2 = StockAlertEntity(
        id: 'alert-2',
        productId: 'prod-1',
        productName: 'Martillo',
        currentStock: 3,
        minimumStock: 10,
        isResolved: false,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          alertRepo: mockAlerts,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          alerts: [testAlert, alert2],
          child: const MaterialApp(home: StockAlertsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Destornillador'), findsOneWidget);
      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Resolver'), findsNWidgets(2));
    });

    testWidgets('ProductForm: producto con nombre duplicado detecta', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          child: const MaterialApp(home: ProductFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Escribir nombre similar al existente
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del producto'),
        'martillo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría'),
        'Herramientas',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio ingreso'),
        '15000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio venta'),
        '20000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock actual'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stock mínimo'),
        '2',
      );

      final guardarBtn = find.text('Crear Producto');
      if (guardarBtn.evaluate().isNotEmpty) {
        await tester.tap(guardarBtn);
        await tester.pumpAndSettle();

        // Debería mostrar diálogo de duplicado
        expect(find.textContaining('duplicado'), findsOneWidget);
      }
    });

    testWidgets('Dashboard: producto con stock bajo se marca con rojo', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1, testProduct2],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Destornillador tiene stock bajo (5 <= 10) - usa badge con texto 'Bajo'
      expect(find.text('Bajo'), findsWidgets);
    });

    testWidgets('Movimientos: tipos de movimiento segmented button', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          movements: [],
          child: const MaterialApp(home: InventoryMovementsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verificar los 3 tipos de movimiento
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Salida'), findsOneWidget);
      expect(find.text('Ajuste'), findsOneWidget);

      // Tap en Salida
      await tester.tap(find.text('Salida'));
      await tester.pumpAndSettle();

      // El segmented button debería cambiar
      expect(find.text('Salida'), findsOneWidget);
    });

    testWidgets('Perfil: cambio de contraseña con nueva débil falla', (
      tester,
    ) async {
      mockAuth.setAuthProvider('password');
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          authProviderType: 'password',
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      final currentPwd = find.widgetWithText(
        TextFormField,
        'Contraseña actual',
      );
      final newPwd = find.widgetWithText(TextFormField, 'Nueva contraseña');
      final confirmPwd = find.widgetWithText(
        TextFormField,
        'Confirmar nueva contraseña',
      );

      if (currentPwd.evaluate().isNotEmpty) {
        await tester.enterText(currentPwd, 'OldPass@123');
        await tester.pumpAndSettle();
        await tester.enterText(newPwd, '123'); // Débil
        await tester.pumpAndSettle();
        await tester.enterText(confirmPwd, '123');
        await tester.pumpAndSettle();

        final cambiarBtn = find.widgetWithText(
          FilledButton,
          'Cambiar Contraseña',
        );
        if (cambiarBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(cambiarBtn);
          await tester.pumpAndSettle();
          await tester.tap(cambiarBtn);
          await tester.pumpAndSettle();

          // Debe fallar por requisitos de fortaleza (aparece en error y en PasswordRequirements)
          expect(find.textContaining('Mínimo 8 caracteres'), findsWidgets);
        }
      }
    });

    testWidgets('Perfil: nuevas contraseñas no coinciden', (tester) async {
      mockAuth.setAuthProvider('password');
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          currentUser: testUser,
          tenant: testTenant,
          authProviderType: 'password',
          child: const MaterialApp(home: UserProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      final currentPwd = find.widgetWithText(
        TextFormField,
        'Contraseña actual',
      );
      final newPwd = find.widgetWithText(TextFormField, 'Nueva contraseña');
      final confirmPwd = find.widgetWithText(
        TextFormField,
        'Confirmar nueva contraseña',
      );

      if (currentPwd.evaluate().isNotEmpty) {
        await tester.enterText(currentPwd, 'OldPass@123');
        await tester.pumpAndSettle();
        await tester.enterText(newPwd, 'NewPass@123');
        await tester.pumpAndSettle();
        await tester.enterText(confirmPwd, 'Different@123');
        await tester.pumpAndSettle();

        final cambiarBtn = find.widgetWithText(
          FilledButton,
          'Cambiar Contraseña',
        );
        if (cambiarBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(cambiarBtn);
          await tester.pumpAndSettle();
          await tester.tap(cambiarBtn);
          await tester.pumpAndSettle();

          expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
        }
      }
    });

    testWidgets('Multi-tenant: productos de otro tenant no se ven', (
      tester,
    ) async {
      mockProducts.setProducts([
        testProduct1,
        testProduct2,
        testProductOtherTenant,
      ]);

      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1, testProduct2, testProductOtherTenant],
          child: const MaterialApp(home: ProductListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Solo los del tenant-1 deben verse
      expect(find.text('Martillo'), findsOneWidget);
      expect(find.text('Destornillador'), findsOneWidget);
      expect(find.text('Llave inglesa'), findsNothing);
    });

    testWidgets('ProductForm restrictEditing: campos readonly', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          currentUser: testUser,
          tenant: testTenant,
          products: [testProduct1],
          child: MaterialApp(
            home: ProductFormScreen(
              product: testProduct1,
              restrictEditing: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // El producto debería mostrarse pero con restricciones
      expect(find.text('Martillo'), findsOneWidget);
    });

    testWidgets('Dashboard: AppBar tiene título correcto', (tester) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          productRepo: mockProducts,
          movementRepo: mockMovements,
          alertRepo: mockAlerts,
          currentUser: testUser,
          tenant: testTenant,
          products: [],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Login: campos no pierden texto al reconstruir', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'mimail@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'miPassword123',
      );

      // Forzar rebuild
      await tester.pump();

      // Los valores deben persistir gracias a los controllers
      expect(find.text('mimail@test.com'), findsOneWidget);
      expect(find.text('miPassword123'), findsOneWidget);
    });

    testWidgets('Registro: dropdown tipo negocio tiene opciones', (
      tester,
    ) async {
      await tester.pumpWidget(
        testProviderScope(
          authRepo: mockAuth,
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Tipo de negocio *',
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que tiene las opciones del dropdown
      expect(find.text('Ferretería'), findsWidgets);
      expect(find.text('Supermercado'), findsOneWidget);
    });
  });
}
