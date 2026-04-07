import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/presentation/providers/auth_providers.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/providers/inventory_providers.dart';
import 'package:stockia/presentation/providers/product_providers.dart';
import 'package:stockia/presentation/screens/login_screen.dart';
import 'package:stockia/presentation/screens/product_list_screen.dart';
import 'package:stockia/presentation/screens/product_form_screen.dart';
import 'package:stockia/presentation/screens/inventory_movements_screen.dart';
import 'package:stockia/presentation/screens/stock_alerts_screen.dart';
import 'package:stockia/presentation/screens/user_profile_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserEntityProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final alertsAsync = ref.watch(stockAlertsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('StockIA - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            // Reintentar obtener el entity (puede ser race condition)
            Future.microtask(() => ref.invalidate(currentUserEntityProvider));
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(productsStreamProvider);
              ref.invalidate(lowStockProductsProvider);
              ref.invalidate(stockAlertsStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Info del usuario ──
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.deepPurple),
                    title: Text(
                      user.displayName ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('ID: ${user.tenantId}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserProfileScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Resumen de métricas ──
                Row(
                  children: [
                    Expanded(
                      child: productsAsync.when(
                        data: (products) => _MetricCard(
                          icon: Icons.inventory_2,
                          title: 'Productos',
                          value: '${products.length}',
                          color: Colors.blue,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProductListScreen(),
                            ),
                          ),
                        ),
                        loading: () => const _DashboardCardLoading(),
                        error: (e, _) =>
                            _DashboardCardError(error: e.toString()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: lowStockAsync.when(
                        data: (products) => _MetricCard(
                          icon: Icons.warning_amber,
                          title: 'Stock Bajo',
                          value: '${products.length}',
                          color: Colors.orange,
                          onTap: () {},
                        ),
                        loading: () => const _DashboardCardLoading(),
                        error: (e, _) =>
                            _DashboardCardError(error: e.toString()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: alertsAsync.when(
                        data: (alerts) => _MetricCard(
                          icon: Icons.notification_important,
                          title: 'Alertas',
                          value: '${alerts.length}',
                          color: Colors.red,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StockAlertsScreen(),
                            ),
                          ),
                        ),
                        loading: () => const _DashboardCardLoading(),
                        error: (e, _) =>
                            _DashboardCardError(error: e.toString()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Accesos rápidos ──
                Text(
                  'Accesos rápidos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_box,
                        label: 'Nuevo Producto',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProductFormScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.swap_vert,
                        label: 'Movimientos',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const InventoryMovementsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Grid de inventario ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inventario',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final tenantId = ref.read(tenantIdProvider);
                        if (tenantId == null) return;
                        final count = await ref.read(
                          refreshAlertsUseCaseProvider,
                        )(tenantId);
                        ref.invalidate(stockAlertsStreamProvider);
                        ref.invalidate(lowStockProductsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                count > 0
                                    ? 'Se encontraron $count producto(s) con stock bajo'
                                    : 'Todos los productos tienen stock suficiente',
                              ),
                              backgroundColor: count > 0
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                productsAsync.when(
                  data: (products) => products.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No hay productos registrados.\nAgrega tu primer producto desde "Nuevo Producto".',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      : _InventoryGrid(
                          products: products,
                          onEdit: (product) => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductFormScreen(
                                product: product,
                                restrictEditing: true,
                              ),
                            ),
                          ),
                          onDelete: (product) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar producto'),
                                content: Text('¿Eliminar "${product.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref.read(deleteProductUseCaseProvider)(
                                product.id,
                              );
                            }
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _DashboardCardError(error: e.toString()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCardLoading extends StatelessWidget {
  const _DashboardCardLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _DashboardCardError extends StatelessWidget {
  final String error;
  const _DashboardCardError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 36, color: Colors.deepPurple),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StockFilter { todos, bajo, ok }

class _InventoryGrid extends StatefulWidget {
  final List<ProductEntity> products;
  final void Function(ProductEntity) onEdit;
  final void Function(ProductEntity) onDelete;

  const _InventoryGrid({
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_InventoryGrid> createState() => _InventoryGridState();
}

class _InventoryGridState extends State<_InventoryGrid> {
  _StockFilter _filter = _StockFilter.todos;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final filtered = switch (_filter) {
      _StockFilter.todos => widget.products,
      _StockFilter.bajo => widget.products.where((p) => p.isLowStock).toList(),
      _StockFilter.ok => widget.products.where((p) => !p.isLowStock).toList(),
    };

    return Center(
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 12),
              child: SegmentedButton<_StockFilter>(
                segments: const [
                  ButtonSegment(
                    value: _StockFilter.todos,
                    label: Text('Todos'),
                  ),
                  ButtonSegment(value: _StockFilter.bajo, label: Text('Bajo')),
                  ButtonSegment(value: _StockFilter.ok, label: Text('OK')),
                ],
                selected: {_filter},
                onSelectionChanged: (v) => setState(() => _filter = v.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Colors.deepPurple.shade50,
                ),
                columnSpacing: 24,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Producto',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Cantidad Disponible',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Cantidad Mínima',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Precio Ingreso',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Precio Venta',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Valor Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Estado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Acciones',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: filtered.map((p) {
                  final totalValue = p.stock * p.salePrice;
                  return DataRow(
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(Text('${p.stock}')),
                      DataCell(Text('${p.minimumStock}')),
                      DataCell(Text(currencyFormat.format(p.costPrice))),
                      DataCell(Text(currencyFormat.format(p.salePrice))),
                      DataCell(Text(currencyFormat.format(totalValue))),
                      DataCell(_StockBadge(isLow: p.isLowStock)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blue,
                              ),
                              tooltip: 'Editar',
                              onPressed: () => widget.onEdit(p),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              tooltip: 'Eliminar',
                              onPressed: () => widget.onDelete(p),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool isLow;
  const _StockBadge({required this.isLow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Text(
        isLow ? 'Bajo' : 'OK',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isLow ? Colors.red.shade700 : Colors.green.shade700,
        ),
      ),
    );
  }
}
