import 'package:flutter/material.dart';
import 'package:homeventory/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? initialDescription;
  final double? initialAmount;
  final DateTime? initialDate;
  final String source;

  const AddExpenseScreen({
    super.key,
    this.initialDescription,
    this.initialAmount,
    this. initialDate,
    this.source = 'manual',
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
} 

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late DateTime _date;
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoadingCategories = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    _amountCtrl = TextEditingController(
      text: widget.initialAmount != null ? widget.initialAmount!.toStringAsFixed(0) : ''
    );
    _date = widget.initialDate ?? DateTime.now();
    _loadCategories();
  }

   Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final cats = await ApiService().getCategories();
      setState(() => _categories = cats);
    } catch (e) {
      setState(() => _error = 'Failed to load categories.');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, 
      initialDate: _date,
      firstDate: DateTime(2020), 
      lastDate: DateTime.now().add(const Duration(days: 1))
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_descCtrl.text.isEmpty) {
      setState(() => _error = 'Description is required');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ApiService().addExpense({
        'description': _descCtrl.text.trim(),
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'category': _selectedCategory?.id,
        'source': widget.source,
      });

      if (mounted) context.go('/expenses');
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG expense submit error: $e');
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        leading: IconButton(
          onPressed: () => context.go('/expenses'), 
          icon: const Icon(Icons.arrow_back))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Weekly groceries in Indomaret',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            const Text('Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(DateFormat('d MMMM yyyy').format(_date)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Category (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _isLoadingCategories
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<Category>(
                initialValue: _selectedCategory,
                isExpanded: true,
                hint: const Text('None'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child:  Text(cat.name))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit, 
                icon: _isSubmitting
                  ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Saving' : 'Save expense')),
            ),
          ],
        ),
      ),
    );
  }
}