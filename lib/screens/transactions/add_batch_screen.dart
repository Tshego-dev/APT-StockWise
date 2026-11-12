import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/product.dart';
import '../../models/stock_batch.dart';
import '../../models/stock_transaction.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class AddBatchScreen extends StatefulWidget {
  final Product product;
  const AddBatchScreen({super.key, required this.product});

  @override
  State<AddBatchScreen> createState() => _AddBatchScreenState();
}

class _AddBatchScreenState extends State<AddBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _loading = false;

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final batchId = const Uuid().v4();
    final batch = StockBatch(
      id: batchId,
      productId: widget.product.id,
      quantity: int.parse(_qtyCtrl.text),
      expiryDate: _expiryDate,
      receivedDate: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    try {
      await InventoryService.addBatch(batch);
      await InventoryService.recordTransaction(
        productId: widget.product.id,
        batchId: batchId,
        type: TransactionType.stockIn,
        quantity: batch.quantity,
        notes: 'New batch received',
      );
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.check_rounded, color: AppTheme.safeColor, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Batch Added!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'A new batch of ${batch.quantity} units for "${widget.product.name}" has been successfully added.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
        if (mounted) Navigator.pop(context);
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
      appBar: AppBar(title: Text('Add Batch — ${widget.product.name}')),
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              InkWell(
                onTap: _pickExpiry,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormatter.format(_expiryDate)),
                ),
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
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add Batch'),
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
