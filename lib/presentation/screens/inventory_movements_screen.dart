import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/providers/inventory_providers.dart';
import 'package:stockia/presentation/providers/product_providers.dart';

class InventoryMovementsScreen extends ConsumerWidget {
  const InventoryMovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos de Inventario')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMovementDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: movementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (movements) {
          if (movements.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_vert, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay movimientos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];
              return _MovementTile(movement: movement);
            },
          );
        },
      ),
    );
  }

  void _showCreateMovementDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _CreateMovementForm(),
      ),
    );
  }
}

class _MovementTile extends ConsumerWidget {
  final InventoryMovementEntity movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = switch (movement.type) {
      MovementType.IN => (Icons.arrow_downward, Colors.green),
      MovementType.OUT => (Icons.arrow_upward, Colors.red),
      MovementType.ADJUSTMENT => (Icons.tune, Colors.orange),
    };

    final productsAsync = ref.watch(productsStreamProvider);
    final productName =
        productsAsync.whenOrNull(
          data: (products) {
            final match = products.where((p) => p.id == movement.productId);
            return match.isNotEmpty ? match.first.name : movement.productId;
          },
        ) ??
        movement.productId;

    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(movement.type.label),
        subtitle: Text(
          'Producto: $productName\n'
          'Fecha: ${movement.date.day}/${movement.date.month}/${movement.date.year}'
          '${movement.notes != null && movement.notes!.isNotEmpty ? '\nObs: ${movement.notes}' : ''}',
        ),
        trailing: Text(
          '${movement.type == MovementType.OUT ? "-" : "+"}${movement.quantity}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CreateMovementForm extends ConsumerStatefulWidget {
  const _CreateMovementForm();

  @override
  ConsumerState<_CreateMovementForm> createState() =>
      _CreateMovementFormState();
}

class _CreateMovementFormState extends ConsumerState<_CreateMovementForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  MovementType _selectedType = MovementType.IN;
  String? _selectedProductId;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un producto')));
      return;
    }

    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) return;

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final movement = InventoryMovementEntity(
        id: '',
        type: _selectedType,
        quantity: int.parse(_quantityController.text.trim()),
        productId: _selectedProductId!,
        date: now,
        tenantId: tenantId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(registerMovementUseCaseProvider)(movement);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nuevo Movimiento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(value: MovementType.IN, label: Text('Entrada')),
                ButtonSegment(value: MovementType.OUT, label: Text('Salida')),
                ButtonSegment(
                  value: MovementType.ADJUSTMENT,
                  label: Text('Ajuste'),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (types) =>
                  setState(() => _selectedType = types.first),
            ),
            const SizedBox(height: 16),
            productsAsync.when(
              data: (products) => DropdownButtonFormField<String>(
                value: _selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(),
                ),
                items: products
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (Stock: ${p.stock})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedProductId = v),
                validator: (v) => v == null ? 'Selecciona un producto' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error cargando productos: $e'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Ingresa un número positivo';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: const Text('Registrar Movimiento'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
