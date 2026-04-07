import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/user_entity.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  group('UserEntity', () {
    test('se crea correctamente con todos los campos', () {
      expect(testUser.id, 'user-1');
      expect(testUser.email, 'test@stockia.com');
      expect(testUser.tenantId, 'tenant-1');
      expect(testUser.displayName, 'Test User');
    });

    test('toMap genera mapa correcto', () {
      final map = testUser.toMap();
      expect(map['email'], 'test@stockia.com');
      expect(map['tenantId'], 'tenant-1');
      expect(map['displayName'], 'Test User');
      expect(map.containsKey('id'), false);
    });

    test('fromMap reconstruye la entidad', () {
      final map = testUser.toMap();
      final rebuilt = UserEntity.fromMap('user-1', map);
      expect(rebuilt.id, testUser.id);
      expect(rebuilt.email, testUser.email);
      expect(rebuilt.tenantId, testUser.tenantId);
    });

    test('copyWith modifica solo los campos indicados', () {
      final copy = testUser.copyWith(displayName: 'Nuevo Nombre');
      expect(copy.displayName, 'Nuevo Nombre');
      expect(copy.email, testUser.email);
      expect(copy.tenantId, testUser.tenantId);
    });
  });

  group('TenantEntity', () {
    test('se crea correctamente', () {
      expect(testTenant.name, 'Ferretería El Martillo');
      expect(testTenant.nit, '900.123.456-7');
      expect(testTenant.businessType, 'Ferretería');
      expect(testTenant.legalRepresentative, 'Juan Pérez');
    });

    test('toMap genera mapa correcto', () {
      final map = testTenant.toMap();
      expect(map['name'], 'Ferretería El Martillo');
      expect(map['nit'], '900.123.456-7');
      expect(map['businessType'], 'Ferretería');
      expect(map['legalRepresentative'], 'Juan Pérez');
      expect(map.containsKey('createdAt'), true);
    });
  });

  group('ProductEntity', () {
    test('se crea correctamente', () {
      expect(testProduct1.name, 'Martillo');
      expect(testProduct1.stock, 50);
      expect(testProduct1.minimumStock, 10);
      expect(testProduct1.costPrice, 18000);
      expect(testProduct1.salePrice, 25000);
      expect(testProduct1.tenantId, 'tenant-1');
    });

    test('isLowStock retorna false cuando stock > minimumStock', () {
      expect(testProduct1.isLowStock, false);
    });

    test('isLowStock retorna true cuando stock <= minimumStock', () {
      expect(testProduct2.isLowStock, true);
    });

    test('toMap genera mapa sin id', () {
      final map = testProduct1.toMap();
      expect(map.containsKey('id'), false);
      expect(map['name'], 'Martillo');
      expect(map['stock'], 50);
      expect(map['minimumStock'], 10);
      expect(map['costPrice'], 18000);
      expect(map['salePrice'], 25000);
      expect(map['tenantId'], 'tenant-1');
    });

    test('copyWith actualiza stock correctamente', () {
      final updated = testProduct1.copyWith(stock: 100);
      expect(updated.stock, 100);
      expect(updated.name, testProduct1.name);
      expect(updated.salePrice, testProduct1.salePrice);
    });
  });

  group('CategoryEntity', () {
    test('se crea correctamente', () {
      expect(testCategory.name, 'Herramientas manuales');
      expect(testCategory.tenantId, 'tenant-1');
    });

    test('toMap genera mapa correcto', () {
      final map = testCategory.toMap();
      expect(map['name'], 'Herramientas manuales');
      expect(map['tenantId'], 'tenant-1');
      expect(map.containsKey('createdAt'), true);
    });
  });

  group('InventoryMovementEntity', () {
    test('se crea movimiento IN correctamente', () {
      expect(testMovementIn.type, MovementType.IN);
      expect(testMovementIn.quantity, 20);
      expect(testMovementIn.productId, 'prod-1');
    });

    test('se crea movimiento OUT correctamente', () {
      expect(testMovementOut.type, MovementType.OUT);
      expect(testMovementOut.quantity, 5);
    });

    test('se crea movimiento ADJUSTMENT correctamente', () {
      expect(testMovementAdjustment.type, MovementType.ADJUSTMENT);
      expect(testMovementAdjustment.quantity, 100);
    });

    test('toMap genera type como string', () {
      final map = testMovementIn.toMap();
      expect(map['type'], 'IN');
      expect(map['quantity'], 20);
      expect(map['productId'], 'prod-1');
      expect(map['tenantId'], 'tenant-1');
    });
  });

  group('MovementType', () {
    test('value retorna string correcto', () {
      expect(MovementType.IN.value, 'IN');
      expect(MovementType.OUT.value, 'OUT');
      expect(MovementType.ADJUSTMENT.value, 'ADJUSTMENT');
    });

    test('fromString parsea correctamente', () {
      expect(MovementTypeExtension.fromString('IN'), MovementType.IN);
      expect(MovementTypeExtension.fromString('OUT'), MovementType.OUT);
      expect(
        MovementTypeExtension.fromString('ADJUSTMENT'),
        MovementType.ADJUSTMENT,
      );
    });

    test('fromString lanza error con valor inválido', () {
      expect(
        () => MovementTypeExtension.fromString('INVALID'),
        throwsArgumentError,
      );
    });
  });

  group('StockAlertEntity', () {
    test('se crea correctamente', () {
      expect(testAlert.productName, 'Destornillador');
      expect(testAlert.currentStock, 5);
      expect(testAlert.minimumStock, 10);
      expect(testAlert.isResolved, false);
    });

    test('toMap genera mapa correcto', () {
      final map = testAlert.toMap();
      expect(map['productId'], 'prod-2');
      expect(map['productName'], 'Destornillador');
      expect(map['currentStock'], 5);
      expect(map['minimumStock'], 10);
      expect(map['isResolved'], false);
      expect(map['tenantId'], 'tenant-1');
    });
  });

  group('SignUpData', () {
    test('se crea con todos los campos requeridos', () {
      expect(testSignUpData.email, 'new@stockia.com');
      expect(testSignUpData.password, 'Test@1234');
      expect(testSignUpData.companyName, 'Mi Empresa');
      expect(testSignUpData.nit, '900.999.888-1');
      expect(testSignUpData.businessType, 'Ferretería');
      expect(testSignUpData.legalRepresentative, 'Carlos López');
    });
  });
}
