import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> expenses = [];
  bool isLoading = false;
  String? errorMessage;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Filter expenses by selected month
  List<Expense> get monthlyExpenses {
    return expenses.where((e) =>
      e.date.year == selectedMonth.year &&
      e.date.month == selectedMonth.month
    ).toList()
      ..sort((a,b) => b.date.compareTo(a.date));
  }

  double get monthlyTotal =>
    monthlyExpenses.fold(0, (sum, e) => sum + e.amount);

  // Group category for summary
  Map<String, double> get categoryTotals {
    final map = <String, double>{};
    for (final e in monthlyExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }

    //sort by aount descending
    return Map.fromEntries(
      map.entries.toList()..sort((a,b) => b.value.compareTo(a.value))
    );
  }

  Future<void> fetchExpenses() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final data = await ApiService().getExpenses();
      expenses = data.map((j) => Expense.fromJson(j)).toList();
    } catch (e) {
      errorMessage = parseApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpenses(Expense expense) async {
    try {
      final data = await ApiService().addExpense(expense.toJson());
      expenses.add(Expense.fromJson(data));
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = parseApiError(e);
      notifyListeners();
      return false;
    }
  }

  void previousMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth () {
    final now = DateTime.now();
    if (selectedMonth.year == now.year && selectedMonth.month == now.month) return;
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    notifyListeners();
  }
}