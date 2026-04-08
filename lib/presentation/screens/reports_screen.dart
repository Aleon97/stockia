import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/presentation/providers/inventory_providers.dart';
import 'package:stockia/presentation/providers/product_providers.dart';
import 'package:stockia/presentation/theme/app_theme.dart';

class ReportsScreen extends ConsumerWidget {
  final bool asPage;
  const ReportsScreen({super.key, this.asPage = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final movementsAsync = ref.watch(movementsStreamProvider);
    final alertsAsync = ref.watch(stockAlertsStreamProvider);

    final content = productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        final movements = movementsAsync.valueOrNull ?? [];
        final alertCount = alertsAsync.valueOrNull?.length ?? 0;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sin datos para mostrar',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Agrega productos para ver las gráficas de analítica.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Summary row ──
            _SummaryRow(
              products: products,
              movements: movements,
              alertCount: alertCount,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Row 1: Stock distribution + Category breakdown ──
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 720) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _StockStatusChart(products: products)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: _CategoryChart(products: products)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _StockStatusChart(products: products),
                    const SizedBox(height: AppSpacing.lg),
                    _CategoryChart(products: products),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Row 2: Movement trend + Top products ──
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 720) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MovementTrendChart(movements: movements),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: _TopProductsChart(products: products)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _MovementTrendChart(movements: movements),
                    const SizedBox(height: AppSpacing.lg),
                    _TopProductsChart(products: products),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Row 3: Value distribution ──
            _ValueDistributionChart(products: products),
          ],
        );
      },
    );

    if (asPage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reporte')),
        body: content,
      );
    }
    return content;
  }
}

// ════════════════════════════════════════════════════════════════════
// ── Summary Row
// ════════════════════════════════════════════════════════════════════

class _SummaryRow extends StatelessWidget {
  final List<ProductEntity> products;
  final List<InventoryMovementEntity> movements;
  final int alertCount;

  const _SummaryRow({
    required this.products,
    required this.movements,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalStock = products.fold<int>(0, (s, p) => s + p.stock);
    final totalValue = products.fold<double>(
      0,
      (s, p) => s + p.stock * p.salePrice,
    );
    final lowCount = products.where((p) => p.isLowStock).length;
    final fmtValue = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(totalValue);

    final items = [
      _MiniKpi(
        icon: Icons.inventory_2,
        label: 'Unidades totales',
        value: totalStock.toString(),
        color: AppColors.primary,
      ),
      _MiniKpi(
        icon: Icons.attach_money,
        label: 'Valor inventario',
        value: fmtValue,
        color: AppColors.success,
      ),
      _MiniKpi(
        icon: Icons.warning_amber_rounded,
        label: 'Stock bajo',
        value: lowCount.toString(),
        color: AppColors.warning,
      ),
      _MiniKpi(
        icon: Icons.notification_important,
        label: 'Alertas activas',
        value: alertCount.toString(),
        color: AppColors.danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: items
                .map(
                  (e) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: e,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (e) => SizedBox(
                  width: (constraints.maxWidth - AppSpacing.sm) / 2,
                  child: e,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniKpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ── Chart Card Wrapper
// ════════════════════════════════════════════════════════════════════

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final double height;

  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ── 1. Stock Status Pie Chart (OK vs Low Stock)
// ════════════════════════════════════════════════════════════════════

class _StockStatusChart extends StatelessWidget {
  final List<ProductEntity> products;
  const _StockStatusChart({required this.products});

  @override
  Widget build(BuildContext context) {
    final low = products.where((p) => p.isLowStock).length;
    final ok = products.length - low;

    return _ChartCard(
      title: 'Estado de stock',
      subtitle: '${products.length} productos',
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: [
                  PieChartSectionData(
                    value: ok.toDouble(),
                    title: '$ok',
                    color: AppColors.success,
                    radius: 48,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: low.toDouble(),
                    title: '$low',
                    color: AppColors.danger,
                    radius: 48,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(color: AppColors.success, label: 'Stock OK'),
              const SizedBox(height: AppSpacing.sm),
              _LegendItem(color: AppColors.danger, label: 'Stock bajo'),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ── 2. Category Breakdown Bar Chart
// ════════════════════════════════════════════════════════════════════

class _CategoryChart extends StatelessWidget {
  final List<ProductEntity> products;
  const _CategoryChart({required this.products});

  @override
  Widget build(BuildContext context) {
    // Group by categoryId
    final Map<String, int> catCounts = {};
    for (final p in products) {
      final cat = p.categoryId.isEmpty ? 'Sin categoría' : p.categoryId;
      catCounts[cat] = (catCounts[cat] ?? 0) + 1;
    }
    final entries = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      AppColors.textTertiary,
    ];

    return _ChartCard(
      title: 'Productos por categoría',
      subtitle: '${catCounts.length} categorías',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (top.isEmpty ? 1 : top.first.value.toDouble()) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gIdx, rod, rIdx) {
                final entry = top[group.x.toInt()];
                return BarTooltipItem(
                  '${entry.key}\n${entry.value}',
                  GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i >= top.length) return const SizedBox.shrink();
                  final label = top[i].key;
                  return SideTitleWidget(
                    meta: meta,
                    child: SizedBox(
                      width: 56,
                      child: Text(
                        label.length > 8 ? '${label.substring(0, 8)}…' : label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(top.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: top[i].value.toDouble(),
                  color: colors[i % colors.length],
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ── 3. Movement Trend (last 7 days) Line Chart
// ════════════════════════════════════════════════════════════════════

class _MovementTrendChart extends StatelessWidget {
  final List<InventoryMovementEntity> movements;
  const _MovementTrendChart({required this.movements});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayFmt = DateFormat('dd/MM');

    // Build 7-day buckets
    final Map<String, int> inMap = {};
    final Map<String, int> outMap = {};
    final List<String> labels = [];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      labels.add(dayFmt.format(d));
      inMap[key] = 0;
      outMap[key] = 0;
    }
    for (final m in movements) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      if (m.type == MovementType.IN) {
        inMap[key] = (inMap[key] ?? 0) + m.quantity;
      } else if (m.type == MovementType.OUT) {
        outMap[key] = (outMap[key] ?? 0) + m.quantity;
      }
    }

    final inValues = inMap.values.toList();
    final outValues = outMap.values.toList();
    final maxY = [
      ...inValues,
      ...outValues,
    ].fold<int>(0, (m, v) => v > m ? v : m).toDouble();

    return _ChartCard(
      title: 'Movimientos últimos 7 días',
      subtitle: 'Entradas vs Salidas',
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 5 : maxY * 1.2,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final isIn = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isIn ? "Entradas" : "Salidas"}: ${spot.y.toInt()}',
                  GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY == 0 ? 1 : null,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    labels[i],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Entradas
            LineChartBarData(
              spots: List.generate(
                7,
                (i) => FlSpot(i.toDouble(), inValues[i].toDouble()),
              ),
              isCurved: true,
              color: AppColors.success,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.success.withValues(alpha: 0.1),
              ),
            ),
            // Salidas
            LineChartBarData(
              spots: List.generate(
                7,
                (i) => FlSpot(i.toDouble(), outValues[i].toDouble()),
              ),
              isCurved: true,
              color: AppColors.danger,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.danger.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ── 4. Top 5 Products by Stock (horizontal bar)
// ════════════════════════════════════════════════════════════════════

class _TopProductsChart extends StatelessWidget {
  final List<ProductEntity> products;
  const _TopProductsChart({required this.products});

  @override
  Widget build(BuildContext context) {
    final sorted = [...products]..sort((a, b) => b.stock.compareTo(a.stock));
    final top = sorted.take(5).toList();
    final maxVal = top.isEmpty ? 1.0 : top.first.stock.toDouble();

    return _ChartCard(
      title: 'Top 5 productos por stock',
      subtitle: 'Mayor cantidad en inventario',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gIdx, rod, rIdx) {
                final p = top[group.x.toInt()];
                return BarTooltipItem(
                  '${p.name}\n${p.stock} uds',
                  GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i >= top.length) return const SizedBox.shrink();
                  final name = top[i].name;
                  return SideTitleWidget(
                    meta: meta,
                    child: SizedBox(
                      width: 56,
                      child: Text(
                        name.length > 8 ? '${name.substring(0, 8)}…' : name,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(top.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: top[i].stock.toDouble(),
                  color: AppColors.primary,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ── 5. Value Distribution (products by inventory value)
// ════════════════════════════════════════════════════════════════════

class _ValueDistributionChart extends StatelessWidget {
  final List<ProductEntity> products;
  const _ValueDistributionChart({required this.products});

  @override
  Widget build(BuildContext context) {
    final sorted = [
      ...products,
    ]..sort((a, b) => (b.stock * b.salePrice).compareTo(a.stock * a.salePrice));
    final top = sorted.take(8).toList();
    final fmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      const Color(0xFF06B6D4),
      const Color(0xFFF97316),
      AppColors.textTertiary,
    ];

    return _ChartCard(
      title: 'Distribución de valor de inventario',
      subtitle: 'Top 8 productos por valor total',
      height: 340,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(top.length, (i) {
                  final val = top[i].stock * top[i].salePrice;
                  return PieChartSectionData(
                    value: val,
                    title: '',
                    color: colors[i % colors.length],
                    radius: 52,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(top.length, (i) {
                  final val = top[i].stock * top[i].salePrice;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            top[i].name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          fmt.format(val),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ── Legend Item
// ════════════════════════════════════════════════════════════════════

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
