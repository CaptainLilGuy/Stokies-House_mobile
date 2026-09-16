import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  
  @override
  State<StatefulWidget> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().fetchExpenses();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExpenseProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: exp.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month navigator
                _MonthNavigator(exp: exp),

                // Monthly total card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total this month',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onPrimaryContainer)),
                        const SizedBox(height: 4),
                        Text(fmt.format(exp.monthlyTotal),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ),

                //Tabs content
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _HistoryTab(expenses: exp.monthlyExpenses, fmt: fmt),
                      _SummaryTab(totals: exp.categoryTotals, total: exp.monthlyTotal, fmt: fmt),
                    ],
                  ),
                ),
              ], 
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log expense'),
        ),
      );
  }
}

// ─── Month navigator ──────────────────────────────────────

class _MonthNavigator extends StatelessWidget{
  final ExpenseProvider exp;
  const _MonthNavigator({required this.exp});

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = exp.selectedMonth.year == DateTime.now().year &&
      exp.selectedMonth.month == DateTime.now().month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton( 
          icon: const Icon(Icons.chevron_left),
          onPressed: exp.previousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy').format(exp.selectedMonth),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: isCurrentMonth ? null : exp.nextMonth,
            color: isCurrentMonth ? Colors.grey.shade300 : null,
          ),
        ],
      ),
    );
  }
}

// ─── History tab ──────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<Expense> expenses;
  final NumberFormat fmt;
  const _HistoryTab({required this.expenses, required this.fmt});
  
  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('No expenses this month.', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ExpenseProvider>().fetchExpenses(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: expenses.length,
        itemBuilder: (ctx, i) {
          final e = expenses[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                // ignore: deprecated_member_use
                backgroundColor: _categoryColor(e.category).withOpacity(0.15),
                child: Icon(_categoryIcon(e.category),
                    color: _categoryColor(e.category), size: 20),
              ),
              title: Text(e.title, 
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${e.category} . ${DateFormat('d MMM').format(e.date)}'
                '${e.note != null ? '\n${e.note}' : ''}',
              ),
              trailing: Text(fmt.format(e.amount),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Summary tab ──────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final Map<String, double> totals;
  final double total;
  final NumberFormat fmt;
  const _SummaryTab({required this.totals, required this.total, required this.fmt});
  
  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const Center(
        child: Text('No data yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: totals.entries.map((entry) {
        final pct = total > 0 ? entry.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(_categoryIcon(entry.key),
                        size: 16, color: _categoryColor(entry.key)),
                    const SizedBox(width: 8),
                    Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ]),
                  Text(fmt.format(entry.value)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  color: _categoryColor(entry.key),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(height: 2),
              Text('${(pct * 100).toStringAsFixed(1)}% of total',
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Add expense bottom sheet ─────────────────────────────

void _showAddExpenseSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _AddExpenseSheet()
  );
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();
  
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = 'Food';
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;
  String? _error;
  
  static const _categories = [
    'Food', 'Beverage', 'Transport', 'Household', 'Health', 'Personal Care', 'Entertainment', 'Other'
  ];
  
  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }

    setState(() {_isSubmitting = true; _error = null; });

    final expense = Expense(
      id: 0, 
      title: _titleCtrl.text.trim(), 
      amount: amount, 
      category: _category, 
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),  
    );

    final success = await context.read<ExpenseProvider>().addExpenses(expense);
    if (success && mounted) Navigator.pop(context);
    if (!success && mounted) setState(() {_isSubmitting = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Log expense',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Alfamart groceries',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (Rp)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payment_outlined),
            ),
          ),
          const SizedBox(height: 14),

          //Category chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((cat) {
                final sel = _category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat), 
                    selected: sel,
                    onSelected: (_) => setState(() => _category = cat),
                    ),
                  );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          //Date picker row
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context, 
                initialDate: _date,
                firstDate: DateTime(2020), 
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Text(DateFormat('d MMMM yyyy').format(_date)),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note(Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save expense'),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String cat) {
  switch (cat) {
    case 'Food' : return Icons.restaurant_outlined;
    case 'Beverage' : return Icons.local_cafe_outlined;
    case 'Transport' : return Icons.directions_car_outlined;
    case 'Household' : return Icons.home_outlined;
    case 'Health' : return Icons.favorite_outline;
    case 'Personal Care' : return Icons.face_outlined;
    case 'Entertainment' : return Icons.movie_outlined;
    default: return Icons.receipt_outlined;
  }
}

Color _categoryColor(String cat) {
  switch (cat) {
    case 'Food' : return Colors.orange;
    case 'Beverage' : return Colors.blue;
    case 'Transport' : return Colors.indigo;
    case 'Household' : return Colors.teal;
    case 'Health' : return Colors.red;
    case 'Personal Care' : return Colors.pink;
    case 'Entertainment' : return Colors.purple;
  default: return Colors.grey;
  }
}