import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/providers/inventory_providers.dart';

class StockAlertsScreen extends ConsumerWidget {
  const StockAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(stockAlertsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas de Stock')),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay alertas activas',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Todos los productos tienen stock suficiente',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _AlertTile(alert: alert);
            },
          );
        },
      ),
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
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warning, color: Colors.red),
        ),
        title: Text(
          alert.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Stock actual: ${alert.currentStock} | Mínimo: ${alert.minimumStock}\n'
          'Creada: ${alert.createdAt.day}/${alert.createdAt.month}/${alert.createdAt.year}',
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
