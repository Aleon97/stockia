import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/providers/inventory_providers.dart';
import 'package:stockia/presentation/theme/app_theme.dart';

class StockAlertsScreen extends ConsumerWidget {
  final bool asPage;
  const StockAlertsScreen({super.key, this.asPage = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(stockAlertsStreamProvider);

    final body = alertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (alerts) {
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No hay alertas activas',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Todos los productos tienen stock suficiente',
                  style: GoogleFonts.inter(color: AppColors.textTertiary),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AlertTile(alert: alert),
            );
          },
        );
      },
    );

    if (!asPage) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas de Stock')),
      body: body,
    );
  }
}

class _AlertTile extends ConsumerWidget {
  final StockAlertEntity alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: 20,
          ),
        ),
        title: Text(
          alert.productName,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Stock actual: ${alert.currentStock} | Mínimo: ${alert.minimumStock}\n'
          'Creada: ${alert.createdAt.day}/${alert.createdAt.month}/${alert.createdAt.year}',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Resolver alerta'),
                content: Text(
                  '¿Marcar la alerta de "${alert.productName}" como resuelta?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Resolver'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref
                  .read(stockAlertRepositoryProvider)
                  .resolveAlert(alert.id);
            }
          },
          child: const Text('Resolver'),
        ),
        isThreeLine: true,
      ),
    );
  }
}
