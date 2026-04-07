import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/entities/tenant_entity.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/domain/entities/category_entity.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';

final now = DateTime(2026, 4, 2);

// ── Users ──
const testUser = UserEntity(
  id: 'user-1',
  email: 'test@stockia.com',
  tenantId: 'tenant-1',
  displayName: 'Test User',
);

const testUser2 = UserEntity(
  id: 'user-2',
  email: 'other@stockia.com',
  tenantId: 'tenant-2',
  displayName: 'Other User',
);

// ── Tenants ──
final testTenant = TenantEntity(
  id: 'tenant-1',
  name: 'Ferretería El Martillo',
  nit: '900.123.456-7',
  businessType: 'Ferretería',
  legalRepresentative: 'Juan Pérez',
  createdAt: now,
);

// ── Products ──
final testProduct1 = ProductEntity(
  id: 'prod-1',
  name: 'Martillo',
  categoryId: 'cat-1',
  stock: 50,
  minimumStock: 10,
  costPrice: 18000,
  salePrice: 25000,
  tenantId: 'tenant-1',
  createdAt: now,
  updatedAt: now,
);

final testProduct2 = ProductEntity(
  id: 'prod-2',
  name: 'Destornillador',
  categoryId: 'cat-1',
  stock: 5,
  minimumStock: 10,
  costPrice: 8000,
  salePrice: 12000,
  tenantId: 'tenant-1',
  createdAt: now,
  updatedAt: now,
);

final testProductOtherTenant = ProductEntity(
  id: 'prod-3',
  name: 'Llave inglesa',
  categoryId: 'cat-2',
  stock: 20,
  minimumStock: 5,
  costPrice: 25000,
  salePrice: 35000,
  tenantId: 'tenant-2',
  createdAt: now,
  updatedAt: now,
);

// ── Categories ──
final testCategory = CategoryEntity(
  id: 'cat-1',
  name: 'Herramientas manuales',
  tenantId: 'tenant-1',
  createdAt: now,
  updatedAt: now,
);

// ── Inventory Movements ──
final testMovementIn = InventoryMovementEntity(
  id: 'mov-1',
  type: MovementType.IN,
  quantity: 20,
  productId: 'prod-1',
  date: now,
  tenantId: 'tenant-1',
  notes: 'Compra proveedor',
  createdAt: now,
  updatedAt: now,
);

final testMovementOut = InventoryMovementEntity(
  id: 'mov-2',
  type: MovementType.OUT,
  quantity: 5,
  productId: 'prod-1',
  date: now,
  tenantId: 'tenant-1',
  notes: 'Venta al cliente',
  createdAt: now,
  updatedAt: now,
);

final testMovementAdjustment = InventoryMovementEntity(
  id: 'mov-3',
  type: MovementType.ADJUSTMENT,
  quantity: 100,
  productId: 'prod-1',
  date: now,
  tenantId: 'tenant-1',
  notes: 'Ajuste de inventario',
  createdAt: now,
  updatedAt: now,
);

// ── Stock Alerts ──
final testAlert = StockAlertEntity(
  id: 'alert-1',
  productId: 'prod-2',
  productName: 'Destornillador',
  currentStock: 5,
  minimumStock: 10,
  isResolved: false,
  tenantId: 'tenant-1',
  createdAt: now,
  updatedAt: now,
);

// ── SignUp Data ──
const testSignUpData = SignUpData(
  email: 'new@stockia.com',
  password: 'password123',
  companyName: 'Mi Empresa',
  nit: '900.999.888-1',
  businessType: 'Ferretería',
  legalRepresentative: 'Carlos López',
);
