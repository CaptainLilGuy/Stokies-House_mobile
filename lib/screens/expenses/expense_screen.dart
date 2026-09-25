import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        leading: IconButton(
          onPressed: () => context.go('/inventory'),
          icon: const Icon(Icons.arrow_back)),
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
          : exp.errorMessage != null
            ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(exp.errorMessage!, style:const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<ExpenseProvider>().fetchExpenses(), 
                    child: const Text('Reply'),
                    ),
                  ],
                ),
             )
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
        onPressed: () => context.push('/inventory/add-expense'),
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
            icon: const Icon(Icons.chevron_right),
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
                backgroundColor: _categoryColor(e.categoryName).withOpacity(0.15),
                child: Icon(_categoryIcon(e.categoryName),
                    color: _categoryColor(e.categoryName), size: 20),
              ),
              title: Text(e.description, 
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${e.categoryName} . ${DateFormat('d MMM').format(e.date)}'
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

IconData _categoryIcon(String? cat) {
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

Color _categoryColor(String? cat) {
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