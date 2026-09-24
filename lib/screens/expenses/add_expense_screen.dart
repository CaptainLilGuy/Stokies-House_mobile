import 'package:flutter/material.dart';
import 'package:homeventory/services/api_service.dart';
import 'package:provider/provider.dart';
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
        'category': _selectedCategory!.id,
        'source': widget.source,
      });

      if (mounted) context.go('/expense');
    } catch (e) {
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}