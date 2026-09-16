import 'package:flutter/material.dart';
import 'package:homeventory/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_item.dart';
import '../../models/category.dart';


class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
    State<AddItemScreen> createState() => _AddItemScreenState();    
}

class _AddItemScreenState extends State<AddItemScreen>{
  final _nameCtrl = TextEditingController();
  final _quantitCtrl = TextEditingController();
  final _autoAmountctrl = TextEditingController();
  final _autoIntervalCtrl = TextEditingController();
  String _unit = 'pcs';
  DateTime? _expiryDate;
  bool _isSubmitting = false;
  String? _error;
  bool _isLoadingCategories = false;
  bool _autoDecrementEnabled = false;

  static const _units = ['pcs', 'kg', 'g', 'L', 'mL', 'pack', 'box', 'bottle', 'can'];
  List<Category> _categories = [];
  Category? _selectedCategory;
  

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantitCtrl.dispose();
    _autoAmountctrl.dispose();
    _autoIntervalCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final cats = await ApiService().getCategories();
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load categories.');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)), 
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365*5)),
      );
      if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Item is required.');
      return;
    }
    if (_quantitCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Quantity is required.');
      return;
    }
    final qty = double.tryParse(_quantitCtrl.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a valid quantity.');
      return;
    }

    if (_selectedCategory == null) {
      setState(() => _error = 'Please select a category.');
      return;
    }

    final double? autoAmount = double.tryParse(_autoAmountctrl.text.trim());
    final int? autoInterval = int.tryParse(_autoIntervalCtrl.text.trim());
    if (_autoDecrementEnabled) {
      if (autoAmount == null || autoAmount <= 0) {
        setState(() => _error = 'Enter a valid auto-decrement amount.');
        return;
      }
      if (autoInterval == null || autoInterval <= 0) {
        setState(() => _error = 'Enter a valid auto-decrement interval in days.');
        return;
      }
    }

    setState(() {
      _isSubmitting = true; 
      _error = null;
      });
    
    try {
      final item = InventoryItem(
        id: 0, //assign by backend
        name: _nameCtrl.text.trim(), 
        quantity: qty, 
        unit: _unit, 
        categoryId: _selectedCategory!.id,
        expiryDate: _expiryDate,
        autoDecrementAmount: autoAmount,
        autoDecrementIntervalDays: autoInterval,
        );
        print("Quantity: $qty");
        await ApiService().addItem(item.toJson());

      //refresh the list and go back
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
        title: const Text('Add Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inventory'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Item name
            _SectionLabel('Item name'),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Indomie Goreng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 20),

            //Quantity + unit (side by side)
            _SectionLabel('Quantity & Unit'),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                    onChanged: (val) => setState(() => _unit = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              //Category
              _SectionLabel('Category'),
              ButtonTheme(
                alignedDropdown: true,
                child: 
                _isLoadingCategories
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      isExpanded: true,
                      hint: const Text("Select a category"),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.name),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: const Text('Manage Categories'),
                onTap: () => context.go('/inventory/categories'),
              ),
              const SizedBox(height: 20),

              //Expiry date
              _SectionLabel('Expiry date (optional)'),
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

              //AutoDecrement
              _SectionLabel('Auto decrement (optional)'),
              SwitchListTile(
                title: const Text("Enable auto decrement"),
                controlAffinity: ListTileControlAffinity.leading,
                value: _autoDecrementEnabled, 
                onChanged: (val) => setState(() => _autoDecrementEnabled = val),
              ),
              if (_autoDecrementEnabled) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('Amount per Interval'),
                          TextField(
                            controller: _autoAmountctrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel("Interval durations"),
                          TextField(
                            controller: _autoIntervalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Every ___ days',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      )
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              // Error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit, 
                    icon: _isSubmitting
                        ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: Text(_isSubmitting? 'Saving...' : 'Save item'),
                  ),
                ),
            ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),)
    );
  }
}