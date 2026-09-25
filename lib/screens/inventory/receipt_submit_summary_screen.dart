import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReceiptSubmitSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final int? total;
  final String? date;
  const ReceiptSubmitSummaryScreen({
    super.key, 
    required this.results, 
    this.total,
    this.date
  });

  @override
  Widget build(BuildContext context) {
    final succeeded = results.where((r) => r['success'] == true).toList();
    final failed = results.where((r) => r['success'] != true).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Import Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: failed.isEmpty ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  failed.isEmpty ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                  color: failed.isEmpty ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${succeeded.length} of ${results.length} item(s) saved successfully.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...results.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    r['success'] == true ? Icons.check_circle : Icons.error_outline,
                    color: r['success'] == true ? Colors.green : Colors.red,
                  ),
                  title: Text(r['name'] as String),
                  subtitle: r['success'] == true
                      ? Text(r['action'] == 'restocked' ? 'Restocked' : 'Added as new item')
                      : Text(
                          'Failed to ${r['action']}: ${r['error']}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                ),
              )),
          const SizedBox(height: 24),
          if (total != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Log as Expense'),
              onPressed: (){
                DateTime? parsedDate;
                if (date != null && date!.isNotEmpty) {
                  parsedDate = _tryParseReceiptDate(date!);
                }
                context.push('/inventory/add-expense', extra: {
                  'description': 'Groceries (from receipt scan)',
                  'amount': total!.toDouble(),
                  'date': parsedDate ?? DateTime.now(),
                  'source': 'ocr',
                });
              }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/inventory'),
              child: const Text('Back to Inventory'),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _tryParseReceiptDate(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), ' ').trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      var year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null){
        if (year < 100) year += 2000;
          return DateTime.tryParse(
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
        );
      }
    }
    return null;
  }
}