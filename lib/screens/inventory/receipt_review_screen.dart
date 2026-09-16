import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptReviewScreen extends StatefulWidget {
  final Map<String, dynamic> parsedData;

  const ReceiptReviewScreen({super.key, required this.parsedData});

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReviewItem {
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  bool needsReview;

  _ReviewItem({
    required String name,
    required String quantity,
    required String unitPrice,
    required this.needsReview,
  })  : nameController = TextEditingController(text: name),
        qtyController = TextEditingController(text: quantity),
        priceController = TextEditingController(text: unitPrice);

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late List<_ReviewItem> _items;
  late TextEditingController _totalController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();

    final rawItems = (widget.parsedData['items'] as List?) ?? [];
    _items = rawItems.map((item) {
      final map = item as Map<String, dynamic>;
      return _ReviewItem(
        name: map['name']?.toString() ?? '',
        quantity: map['quantity']?.toString() ?? '',
        unitPrice: map['unit_price']?.toString() ?? '',
        needsReview: map['needs_review'] == true,
      );
    }).toList();

    _totalController = TextEditingController(
      text: widget.parsedData['total']?.toString() ?? '',
    );
    _dateController = TextEditingController(
      text: widget.parsedData['date']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _totalController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _deleteItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _addBlankItem() {
    setState(() {
      _items.add(_ReviewItem(name: '', quantity: '', unitPrice: '', needsReview: false));
    });
  }

  void _markReviewed(int index) {
    if (_items[index].needsReview) {
      setState(() {
        _items[index].needsReview = false;
      });
    }
  }

  void _confirmAndContinue() {
    final cleanedItems = _items.map((item) => {
      'name': item.nameController.text.trim(),
      'quantity': int.tryParse(item.qtyController.text.trim()),
      'unit_price': int.tryParse(item.priceController.text.trim()),
    }).where((item) => (item['name'] as String).isNotEmpty).toList();

    final cleanedData = {
      'items': cleanedItems,
      'total': int.tryParse(_totalController.text.trim()),
      'date': _dateController.text.trim(),
    };

    // TODO (Day 10-12 / Day 12-14): route to inventory pre-fill and/or
    // expense pre-fill using cleanedData. For now, just confirm it works.
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmed (temp)'),
        content: SingleChildScrollView(child: Text(cleanedData.toString())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Receipt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.parsedData['layout_detected'] == 'unrecognized')
            _buildWarningBanner(
              'This receipt format wasn\'t recognized — please check items carefully.',
            ),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value)),
          TextButton.icon(
            onPressed: _addBlankItem,
            icon: const Icon(Icons.add),
            label: const Text('Add item manually'),
          ),
          const Divider(height: 32),
          _buildSummaryField('Total', _totalController),
          const SizedBox(height: 12),
          _buildDateField('Date', _dateController),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _confirmAndContinue,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: Colors.orange.shade900, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, _ReviewItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: item.needsReview ? Colors.orange.shade300 : Colors.grey.shade300,
          width: item.needsReview ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: item.needsReview ? Colors.orange.shade50 : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.needsReview)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (_) => _markReviewed(index),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 14, color: Colors.orange.shade800),
                  const SizedBox(width: 4),
                  Text('Please double-check this item',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
                ],
              ),
            ),
          ),
          TextField(
            controller: item.nameController,
            decoration: const InputDecoration(labelText: 'Item name', isDense: true),
            onTap: () => _markReviewed(index),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.qtyController,
                  decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                  keyboardType: TextInputType.number,
                  onTap: () => _markReviewed(index)
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: item.priceController,
                  decoration: const InputDecoration(labelText: 'Unit price', isDense: true),
                  keyboardType: TextInputType.number,
                  onTap: () => _markReviewed(index)
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteItem(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      readOnly: true,
      onTap: ()  async {
        final pickedDate = await showDatePicker(
          context: context, 
          firstDate: DateTime(1900), 
          lastDate: DateTime(2700),
          initialDate: DateTime.now(),
          );

          if (pickedDate != null) {
            setState(() {
              controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
            });
          }
      },
    );
  }
}