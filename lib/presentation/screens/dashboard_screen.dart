import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:stockia/presentation/theme/app_theme.dart';
import 'package:stockia/presentation/widgets/app_shell.dart';

/// Wrapper con Scaffold completo para compat con tests y navegación legacy
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_stockia.png', height: 32),
            const SizedBox(width: 10),
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
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
            Future.microtask(() => ref.invalidate(currentUserEntityProvider));
            return const Center(child: CircularProgressIndicator());
          }
          return _DashboardBody(
            productsAsync: productsAsync,
            lowStockAsync: lowStockAsync,
            alertsAsync: alertsAsync,
            onNavigateProducts: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductListScreen()),
            ),
            onNavigateAlerts: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StockAlertsScreen()),
            ),
            onNavigateMovements: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InventoryMovementsScreen(),
              ),
            ),
            onNavigateProfile: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
            ),
            user: user,
          );
        },
      ),
    );
  }
}

/// Dashboard content widget para embeber dentro del AppShell
class DashboardContent extends ConsumerWidget {
  final void Function(NavSection section)? onNavigate;
  const DashboardContent({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserEntityProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final alertsAsync = ref.watch(stockAlertsStreamProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) {
          Future.microtask(() => ref.invalidate(currentUserEntityProvider));
          return const Center(child: CircularProgressIndicator());
        }
        return _DashboardBody(
          productsAsync: productsAsync,
          lowStockAsync: lowStockAsync,
          alertsAsync: alertsAsync,
          onNavigateProducts: () => onNavigate?.call(NavSection.products),
          onNavigateAlerts: () => onNavigate?.call(NavSection.alerts),
          onNavigateMovements: () => onNavigate?.call(NavSection.movements),
          onNavigateProfile: () => onNavigate?.call(NavSection.settings),
          user: user,
        );
      },
    );
  }
}

/// Body compartido entre DashboardScreen (legacy) y DashboardContent (shell)
class _DashboardBody extends ConsumerWidget {
  final AsyncValue<List<ProductEntity>> productsAsync;
  final AsyncValue<List<ProductEntity>> lowStockAsync;
  final AsyncValue<dynamic> alertsAsync;
  final VoidCallback onNavigateProducts;
  final VoidCallback onNavigateAlerts;
  final VoidCallback onNavigateMovements;
  final VoidCallback onNavigateProfile;
  final dynamic user;

  const _DashboardBody({
    required this.productsAsync,
    required this.lowStockAsync,
    required this.alertsAsync,
    required this.onNavigateProducts,
    required this.onNavigateAlerts,
    required this.onNavigateMovements,
    required this.onNavigateProfile,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productsStreamProvider);
        ref.invalidate(lowStockProductsProvider);
        ref.invalidate(stockAlertsStreamProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // ── KPI Cards ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  _KpiCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Total productos',
                    asyncValue: productsAsync.whenData((p) => '${p.length}'),
                    color: AppColors.primary,
                    bgColor: AppColors.primaryLight,
                    onTap: onNavigateProducts,
                    width: isNarrow ? constraints.maxWidth : null,
                  ),
                  _KpiCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Stock bajo',
                    asyncValue: lowStockAsync.whenData((p) => '${p.length}'),
                    color: AppColors.warning,
                    bgColor: AppColors.warningLight,
                    onTap: onNavigateAlerts,
                    width: isNarrow ? constraints.maxWidth : null,
                  ),
                  _KpiCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Alertas activas',
                    asyncValue: alertsAsync.whenData((a) => '${a.length}'),
                    color: AppColors.danger,
                    bgColor: AppColors.dangerLight,
                    onTap: onNavigateAlerts,
                    width: isNarrow ? constraints.maxWidth : null,
                  ),
                  _KpiCard(
                    icon: Icons.attach_money,
                    title: 'Valor inventario',
                    asyncValue: productsAsync.whenData((products) {
                      final total = products.fold<double>(
                        0,
                        (sum, p) => sum + (p.stock * p.salePrice),
                      );
                      return currencyFormat.format(total);
                    }),
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                    onTap: onNavigateProducts,
                    width: isNarrow ? constraints.maxWidth : null,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Acciones rápidas ──
          Text(
            'Acciones rápidas',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo producto'),
              ),
              OutlinedButton.icon(
                onPressed: onNavigateMovements,
                icon: const Icon(Icons.swap_vert, size: 18),
                label: const Text('Movimientos'),
              ),
              OutlinedButton.icon(
                onPressed: onNavigateAlerts,
                icon: const Icon(Icons.notifications_outlined, size: 18),
                label: const Text('Ver alertas'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Tabla de inventario ──
          Row(
            children: [
              Expanded(
                child: Text(
                  'Inventario',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final tenantId = ref.read(tenantIdProvider);
                  if (tenantId == null) return;
                  final count = await ref.read(refreshAlertsUseCaseProvider)(
                    tenantId,
                  );
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
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          productsAsync.when(
            data: (products) => products.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxxl),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No hay productos registrados',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Agrega tu primer producto desde "Nuevo producto".',
                              style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
                                backgroundColor: AppColors.danger,
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _DashboardCardError(error: e.toString()),
          ),
        ],
      ),
    );
  }
}

// ── KPI Card moderno ──

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final AsyncValue<String> asyncValue;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final double? width;

  const _KpiCard({
    required this.icon,
    required this.title,
    required this.asyncValue,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 210,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      asyncValue.when(
                        data: (value) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, _) => const Text(
                          '--',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    var filtered = switch (_filter) {
      _StockFilter.todos => widget.products,
      _StockFilter.bajo => widget.products.where((p) => p.isLowStock).toList(),
      _StockFilter.ok => widget.products.where((p) => !p.isLowStock).toList(),
    };

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(q))
          .toList();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toolbar ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.md,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SegmentedButton<_StockFilter>(
                        segments: const [
                          ButtonSegment(
                            value: _StockFilter.todos,
                            label: Text('Todos'),
                          ),
                          ButtonSegment(
                            value: _StockFilter.bajo,
                            label: Text('Bajo'),
                          ),
                          ButtonSegment(
                            value: _StockFilter.ok,
                            label: Text('OK'),
                          ),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (v) =>
                            setState(() => _filter = v.first),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.download, size: 20),
                      tooltip: 'Exportar',
                      onSelected: (format) =>
                          _export(format, filtered, currencyFormat),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'pdf',
                          child: ListTile(
                            leading: Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            title: Text('Exportar PDF'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'excel',
                          child: ListTile(
                            leading: Icon(
                              Icons.table_chart,
                              color: Colors.green,
                            ),
                            title: Text('Exportar Excel'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Data Table ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.surfaceVariant,
              ),
              columnSpacing: 24,
              headingTextStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              dataTextStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              columns: const [
                DataColumn(label: Text('Producto')),
                DataColumn(label: Text('Cant. Disponible'), numeric: true),
                DataColumn(label: Text('Cant. Mínima'), numeric: true),
                DataColumn(label: Text('Precio Ingreso'), numeric: true),
                DataColumn(label: Text('Precio Venta'), numeric: true),
                DataColumn(label: Text('Valor Total'), numeric: true),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: filtered.map((p) {
                final totalValue = p.stock * p.salePrice;
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
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
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Editar',
                            onPressed: () => widget.onEdit(p),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.danger,
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
    );
  }

  Future<void> _export(
    String format,
    List<ProductEntity> filtered,
    NumberFormat currencyFormat,
  ) async {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar')),
      );
      return;
    }
    if (format == 'pdf') {
      await _exportPdf(filtered, currencyFormat);
    } else {
      _exportCsv(filtered, currencyFormat);
    }
  }

  Future<void> _exportPdf(
    List<ProductEntity> products,
    NumberFormat currencyFormat,
  ) async {
    final filterLabel = switch (_filter) {
      _StockFilter.todos => 'Todos',
      _StockFilter.bajo => 'Stock Bajo',
      _StockFilter.ok => 'Stock OK',
    };

    try {
      final logoBytes = await rootBundle.load('assets/images/logo_stockia.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.30,
                  child: pw.Image(logoImage, width: 450),
                ),
              ),
            ),
          ),
          header: (context) => pw.Column(
            children: [
              pw.Center(
                child: pw.Text(
                  'StockIA - Inventario',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Filtro: $filterLabel - ${products.length} producto(s) - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.center,
              },
              headers: [
                'Producto',
                'Cant. Disponible',
                'Cant. Mínima',
                'Precio Ingreso',
                'Precio Venta',
                'Valor Total',
                'Estado',
              ],
              data: products.map((p) {
                final totalValue = p.stock * p.salePrice;
                return [
                  p.name,
                  '${p.stock}',
                  '${p.minimumStock}',
                  currencyFormat.format(p.costPrice),
                  currencyFormat.format(p.salePrice),
                  currencyFormat.format(totalValue),
                  p.isLowStock ? 'Bajo' : 'OK',
                ];
              }).toList(),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'StockIA_Inventario_$filterLabel',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      }
    }
  }

  void _exportCsv(List<ProductEntity> products, NumberFormat currencyFormat) {
    final rows = <List<String>>[
      [
        'Producto',
        'Cantidad Disponible',
        'Cantidad Mínima',
        'Precio Ingreso',
        'Precio Venta',
        'Valor Total',
        'Estado',
      ],
      ...products.map((p) {
        final totalValue = p.stock * p.salePrice;
        return [
          p.name,
          '${p.stock}',
          '${p.minimumStock}',
          currencyFormat.format(p.costPrice),
          currencyFormat.format(p.salePrice),
          currencyFormat.format(totalValue),
          p.isLowStock ? 'Bajo' : 'OK',
        ];
      }),
    ];

    final csvString = const ListToCsvConverter().convert(rows);

    final filterLabel = switch (_filter) {
      _StockFilter.todos => 'Todos',
      _StockFilter.bajo => 'StockBajo',
      _StockFilter.ok => 'StockOK',
    };

    if (kIsWeb) {
      _downloadCsvWeb(csvString, 'StockIA_Inventario_$filterLabel.csv');
    } else {
      // For non-web, use printing to share as PDF fallback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportación CSV disponible solo en web. Usa PDF.'),
        ),
      );
    }
  }

  void _downloadCsvWeb(String csvContent, String fileName) {
    final bytes = utf8.encode('\uFEFF$csvContent'); // BOM for Excel
    Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: fileName);
  }
}

class _StockBadge extends StatelessWidget {
  final bool isLow;
  const _StockBadge({required this.isLow});

  @override
  Widget build(BuildContext context) {
    final color = isLow ? AppColors.danger : AppColors.success;
    final bg = isLow ? AppColors.dangerLight : AppColors.successLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Text(
        isLow ? 'Bajo' : 'OK',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
