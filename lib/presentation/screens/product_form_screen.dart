import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/providers/product_providers.dart';
import 'package:stockia/utils/string_normalizer.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductEntity? product;
  final bool restrictEditing;

  const ProductFormScreen({
    super.key,
    this.product,
    this.restrictEditing = false,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _categoryController;
  bool _isLoading = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice.toStringAsFixed(2) ?? '',
    );
    _salePriceController = TextEditingController(
      text: widget.product?.salePrice.toStringAsFixed(2) ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
    _minStockController = TextEditingController(
      text: widget.product?.minimumStock.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.product?.categoryId ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo determinar el tenant')),
      );
      return;
    }

    // Fuzzy duplicate detection
    final newName = _nameController.text.trim();
    final normalizedNew = normalizeForComparison(newName);
    final productsAsync = ref.read(productsStreamProvider);
    final products = productsAsync.valueOrNull ?? [];
    final duplicate = products.where((p) {
      if (_isEditing && p.id == widget.product!.id) return false;
      return normalizeForComparison(p.name) == normalizedNew;
    }).toList();

    if (duplicate.isNotEmpty) {
      final existing = duplicate.first.name;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
          title: const Text('Producto duplicado'),
          content: Text(
            'Ya existe un producto con un nombre similar: "$existing".\n\n¿Deseas continuar de todas formas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final product = ProductEntity(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        categoryId: _categoryController.text.trim(),
        stock: int.parse(_stockController.text.trim()),
        minimumStock: int.parse(_minStockController.text.trim()),
        costPrice: double.parse(_costPriceController.text.trim()),
        salePrice: double.parse(_salePriceController.text.trim()),
        tenantId: tenantId,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await ref.read(updateProductUseCaseProvider)(product);
      } else {
        await ref.read(createProductUseCaseProvider)(product);
      }

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

  Future<void> _delete() async {
    if (widget.product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este producto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(deleteProductUseCaseProvider)(widget.product!.id);
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
    // Keep products stream alive for duplicate detection in _save()
    ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    readOnly: widget.restrictEditing,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      helperText: 'Ej: Herramientas, Alimentos, Electrónica',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio ingreso',
                      prefixIcon: Icon(Icons.arrow_downward),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      if (double.tryParse(v) == null) {
                        return 'Número no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _salePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio venta',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      if (double.tryParse(v) == null) {
                        return 'Número no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stockController,
                    readOnly: widget.restrictEditing,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock actual',
                      prefixIcon: Icon(Icons.inventory),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      if (int.tryParse(v) == null) {
                        return 'Número entero requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minStockController,
                    readOnly: widget.restrictEditing,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo',
                      prefixIcon: Icon(Icons.warning_amber),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      if (int.tryParse(v) == null) {
                        return 'Número entero requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isEditing ? 'Actualizar' : 'Crear Producto'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
