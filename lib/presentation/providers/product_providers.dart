import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/domain/use_cases/product_use_cases.dart';
import 'package:stockia/presentation/providers/core_providers.dart';

// ── Use cases ──
final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  return GetProductsUseCase(ref.watch(productRepositoryProvider));
});

final watchProductsUseCaseProvider = Provider<WatchProductsUseCase>((ref) {
  return WatchProductsUseCase(ref.watch(productRepositoryProvider));
});

final createProductUseCaseProvider = Provider<CreateProductUseCase>((ref) {
  return CreateProductUseCase(
    ref.watch(productRepositoryProvider),
    ref.watch(stockAlertRepositoryProvider),
  );
});

final updateProductUseCaseProvider = Provider<UpdateProductUseCase>((ref) {
  return UpdateProductUseCase(
    ref.watch(productRepositoryProvider),
    ref.watch(stockAlertRepositoryProvider),
  );
});

final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>((ref) {
  return DeleteProductUseCase(
    ref.watch(productRepositoryProvider),
    ref.watch(stockAlertRepositoryProvider),
  );
});

final getLowStockProductsUseCaseProvider = Provider<GetLowStockProductsUseCase>(
  (ref) {
    return GetLowStockProductsUseCase(ref.watch(productRepositoryProvider));
  },
);

final refreshAlertsUseCaseProvider = Provider<RefreshAlertsUseCase>((ref) {
  return RefreshAlertsUseCase(
    ref.watch(productRepositoryProvider),
    ref.watch(stockAlertRepositoryProvider),
  );
});

// ── Products stream ──
final productsStreamProvider = StreamProvider.autoDispose<List<ProductEntity>>((
  ref,
) {
  final tenantId = ref.watch(tenantIdProvider);
  if (tenantId == null) return const Stream.empty();
  return ref.watch(watchProductsUseCaseProvider)(tenantId);
});

// ── Low stock products ──
final lowStockProductsProvider =
    FutureProvider.autoDispose<List<ProductEntity>>((ref) async {
      final tenantId = ref.watch(tenantIdProvider);
      if (tenantId == null) return [];
      return ref.watch(getLowStockProductsUseCaseProvider)(tenantId);
    });
