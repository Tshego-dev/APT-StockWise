import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/stock_batch.dart';
import '../../models/stock_transaction.dart';
import '../../services/database_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class StockTransactionScreen extends StatefulWidget {
  final Product? product;
  final StockBatch? batch;
  const StockTransactionScreen({super.key, this.product, this.batch});

  @override
  State<StockTransactionScreen> createState() => _StockTransactionScreenState();
}

class _StockTransactionScreenState extends State<StockTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Product> _products = [];
  List<StockBatch> _batches = [];
  Product? _selectedProduct;
  StockBatch? _selectedBatch;
  TransactionType _type = TransactionType.sale;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.product;
    _selectedBatch = widget.batch;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseService.getProducts();
    if (mounted) {
      setState(() => _products = products);
      if (_selectedProduct != null) _loadBatches(_selectedProduct!.id);
    }
  }

  Future<void> _loadBatches(String productId) async {
    final batches = await DatabaseService.getBatchesForProduct(productId);
    if (mounted) setState(() => _batches = batches);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a product')));
      return;
    }
    setState(() => _loading = true);
    try {
      await InventoryService.recordTransaction(
        productId: _selectedProduct!.id,
        batchId: _selectedBatch?.id,
        type: _type,
        quantity: int.parse(_qtyCtrl.text),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction recorded')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.expiryColor),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Transaction')),
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction type selector
              Text('Transaction Type', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TransactionType.values.map((t) {
                  final labels = {
                    TransactionType.sale: 'Sale',
                    TransactionType.stockIn: 'Stock In',
                    TransactionType.damaged: 'Damaged',
                    TransactionType.disposal: 'Disposal',
                    TransactionType.adjustment: 'Adjustment',
                  };
                  return ChoiceChip(
                    label: Text(labels[t]!),
                    selected: _type == t,
                    selectedColor: AppTheme.primary.withOpacity(0.2),
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Product selector
              if (widget.product == null)
                DropdownButtonFormField<Product>(
                  value: _selectedProduct,
                  decoration: const InputDecoration(labelText: 'Product *'),
                  items: _products
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (p) {
                    setState(() { _selectedProduct = p; _selectedBatch = null; });
                    if (p != null) _loadBatches(p.id);
                  },
                  validator: (v) => v == null ? 'Select a product' : null,
                )
              else
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Product'),
                  child: Text(widget.product!.name),
                ),
              const SizedBox(height: 16),
              // Batch selector
              if (_batches.isNotEmpty)
                DropdownButtonFormField<StockBatch>(
                  value: _selectedBatch,
                  decoration: const InputDecoration(labelText: 'Batch (optional)'),
                  items: _batches
                      .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                                '${b.quantity} units — Exp: ${DateFormatter.shortFormat(b.expiryDate)}'),
                          ))
                      .toList(),
                  onChanged: (b) => setState(() => _selectedBatch = b),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity *'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n <= 0 ? 'Enter a valid quantity' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Record Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
