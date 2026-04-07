import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/use_cases/inventory_use_cases.dart';
import 'package:stockia/presentation/providers/core_providers.dart';

// ── Use cases ──
final registerMovementUseCaseProvider = Provider<RegisterMovementUseCase>((
  ref,
) {
  return RegisterMovementUseCase(
    ref.watch(inventoryMovementRepositoryProvider),
    ref.watch(productRepositoryProvider),
    ref.watch(stockAlertRepositoryProvider),
  );
});

final watchMovementsUseCaseProvider = Provider<WatchMovementsUseCase>((ref) {
  return WatchMovementsUseCase(ref.watch(inventoryMovementRepositoryProvider));
});

// ── Movements stream ──
final movementsStreamProvider =
    StreamProvider.autoDispose<List<InventoryMovementEntity>>((ref) {
      final tenantId = ref.watch(tenantIdProvider);
      if (tenantId == null) return const Stream.empty();
      return ref.watch(watchMovementsUseCaseProvider)(tenantId);
    });

// ── Stock alerts stream ──
final stockAlertsStreamProvider = StreamProvider.autoDispose((ref) {
  final tenantId = ref.watch(tenantIdProvider);
  if (tenantId == null) return const Stream.empty();
  return ref.watch(stockAlertRepositoryProvider).watchActiveAlerts(tenantId);
});
