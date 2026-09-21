import 'package:flutter/material.dart';
import 'package:homeventory/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_item.dart';
import '../../models/category.dart';

class EditItemScreen extends StatefulWidget {
  final InventoryItem item;
  const EditItemScreen({super.key, required this.item});

  @override
  State<StatefulWidget> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _autoAmountCtrl;
  late final TextEditingController _autoIntervalCtrl;
  late String _unit;
  DateTime? _expiryDate;
  bool _isSubmitting = false;
  String? _error;
  bool _isLoadingCategories = false;
  late bool _autoDecrementEnabled;

  static const _units = ['pcs', 'kg', 'g', 'L', 'mL', 'pack', 'box', 'bottle', 'can'];
  List<Category> _categories = [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item.name);
    _unit = item.unit;
    _expiryDate = item.expiryDate;
    _autoAmountCtrl = TextEditingController(text: item.autoDecrementAmount?.toString() ?? '');
    _autoIntervalCtrl = TextEditingController(text: item.autoDecrementIntervalDays?.toString() ?? '');
    _autoDecrementEnabled = item.autoDecrementAmount != null && item.autoDecrementIntervalDays != null;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final cats = await ApiService().getCategories();
      setState(() {
        _categories = cats;
        _selectedCategory = cats.firstWhere(
         (c) => c.id == widget.item.categoryId,
         orElse: () => cats.isNotEmpty ? cats.first : throw StateError('No Categories'), 
        );
      });
    } catch (e) {
      setState(() => _error = 'Failed to load categories');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _autoAmountCtrl.dispose();
    _autoIntervalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)), 
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = "Name is required");
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _error = "Please select a category");
      return;
    }

    final double? autoAmount = double.tryParse(_autoAmountCtrl.text.trim());
    final int? autoInterval = int.tryParse(_autoIntervalCtrl.text.trim());
    if (_autoDecrementEnabled){
      if (autoAmount == null || autoAmount < 0) {
        setState(() => _error = 'Enter a valid auto-decrement amount');
        return;
      }
      if (autoInterval == null || autoInterval < 0) {
        setState(() => _error = 'Enter a valid auto-interval amount');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'unit': _unit,
        'category': _selectedCategory!.id,
        'expiry_date': _expiryDate?.toIso8601String(),
        'auto_decrement_amount': _autoDecrementEnabled ? autoAmount : null,
        'auto_decrement_interval_days': _autoDecrementEnabled ? autoInterval : null,
      };

      await ApiService().updateItem(widget.item.id, payload);

      if (mounted) {
        await context.read<InventoryProvider>().fetchItems();
        // ignore: use_build_context_synchronously
        context.go('/inventory');
      }
    } catch (e) {
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inventory'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _sectionLabel('Item Name'),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // _SectionLabel('Unit'),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _units
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(), 
              onChanged: (val) => setState(() => _unit = val!),
            ),
            const SizedBox(height: 20),
            
            //_SectionLabel('Expiry Date (Optional)'),
            InkWell(
              onTap: _pickExpiry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      _expiryDate != null
                        ? DateFormat('d MMMM yyyy').format(_expiryDate!)
                        : 'Tap to select a date',
                      style: TextStyle(
                        color: _expiryDate != null ? Colors.black87 : Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (_expiryDate != null) 
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            
          ],
        ),
      ),
    );
  }
}