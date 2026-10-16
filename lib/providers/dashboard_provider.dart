import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/expense.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

enum SpendStatus { noBudget, tooEarly, onTrack, fasterThanUsual, overBudget }

class UsageCount {
  final String name;
  final int count;
  const UsageCount(this.name, this.count);
}



/// Client-side v1: derives the cards from endpoints that already exist.
/// When the aggregated GET /dashboard/ endpoint is built, replace fetch()
/// and keep every getter below as the UI contract.
class DashboardProvider extends ChangeNotifier {
  // Tunable DSS assumptions (test these in UAT)
  static const expiryWindowDays = 3;
  static const paceMarginPoints = 15;
  static const warnFromDay = 7;
  static const unlockLogCount = 5;

  static const _budgetKey = 'monthly_budget'; // interim: move to Household
  final _storage = const FlutterSecureStorage();

  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;

  List<InventoryItem> expiring = [];
  List<Expense> monthExpenses = [];
  double spent = 0;
  double? budget;
  int usageLogCount = 0;
  int wastedThisMonth = 0;
  int wastedLastMonth = 0;
  List<UsageCount> topUsed = [];
  final Set<String> hidden = {};

  // ── derived values ──────────────────────────────────────
  DateTime get _now => DateTime.now();
  int get dayOfMonth => _now.day;
  int get daysInMonth => DateTime(_now.year, _now.month + 1, 0).day;
  double get paceFraction => dayOfMonth / daysInMonth;
  double get spentFraction =>
      (budget == null || budget! <= 0) ? 0 : spent / budget!;

  SpendStatus get spendStatus {
    if (budget == null || budget! <= 0) return SpendStatus.noBudget;
    if (spent >= budget!) return SpendStatus.overBudget;
    if (dayOfMonth < warnFromDay) return SpendStatus.tooEarly;
    final usedPct = spentFraction * 100;
    final pacePct = paceFraction * 100;
    return usedPct > pacePct + paceMarginPoints
        ? SpendStatus.fasterThanUsual
        : SpendStatus.onTrack;
  }

  bool get patternUnlocked => usageLogCount >= unlockLogCount;

  static int daysLeft(InventoryItem i) {
    final e = i.expiryDate!;
    final n = DateTime.now();
    return DateTime(e.year, e.month, e.day)
        .difference(DateTime(n.year, n.month, n.day))
        .inDays;
  }

  // ── loading ─────────────────────────────────────────────
  Future<void> fetch({bool silent = false}) async {
    if (!silent && !hasLoaded) {
      isLoading = true;
      notifyListeners();
    }
    errorMessage = null;
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getInventory(),
        api.getExpenses(),
        api.getTransactions(),
      ]);
      final items = results[0]
          .map((j) => InventoryItem.fromJson(Map<String, dynamic>.from(j)))
          .toList();
      final expenses = results[1]
          .map((j) => Expense.fromJson(Map<String, dynamic>.from(j)))
          .toList();
      final txns = results[2].map((j) => Map<String, dynamic>.from(j)).toList();

      final b = await _storage.read(key: _budgetKey);
      budget = b == null ? null : double.tryParse(b);

      _computeExpiring(items);
      _computeSpending(expenses);
      _computeTransactions(txns, items);
      hasLoaded = true;
    } catch (e) {
      errorMessage = parseApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _computeExpiring(List<InventoryItem> items) {
    expiring = items
        .where((i) =>
            i.expiryDate != null &&
            i.quantity > 0 &&
            daysLeft(i) <= expiryWindowDays)
        .toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
  }

  void _computeSpending(List<Expense> all) {
    final n = _now;
    monthExpenses = all
        .where((e) => e.date.year == n.year && e.date.month == n.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    spent = monthExpenses.fold(0.0, (s, e) => s + e.amount);
  }

  void _computeTransactions(
      List<Map<String, dynamic>> txns, List<InventoryItem> items) {
    final n = _now;
    final names = {for (final i in items) i.id: i.name};
    final counts = <int, int>{};
    usageLogCount = 0;
    wastedThisMonth = 0;
    wastedLastMonth = 0;
    final lastMonth = DateTime(n.year, n.month - 1);

    for (final t in txns) {
      final type = t['change_type'];
      final at = DateTime.tryParse(t['created_at']?.toString() ?? '')?.toLocal();
      if (type == 'consumed' && t['source'] == 'manual') {
        usageLogCount++;
        final id = t['item'] as int?;
        if (id != null) counts[id] = (counts[id] ?? 0) + 1;
      }
      if (type == 'wasted' && at != null) {
        if (at.year == n.year && at.month == n.month) wastedThisMonth++;
        if (at.year == lastMonth.year && at.month == lastMonth.month) {
          wastedLastMonth++;
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topUsed = [
      for (final e in sorted.take(3))
        if (names[e.key] != null) UsageCount(names[e.key]!, e.value)
    ];
  }

  // ── actions ─────────────────────────────────────────────
  /// Returns an error message, or null on success.
  Future<String?> logUsage(InventoryItem item,
      {required bool wasted, required double qty}) async {
    try {
      await ApiService().logUsage(item.id, qty, wasted: wasted);
      await fetch(silent: true);
      return null;
    } catch (e) {
      return parseApiError(e);
    }
  }

  Future<void> setBudget(double value) async {
    budget = value;
    await _storage.write(key: _budgetKey, value: value.toStringAsFixed(0));
    notifyListeners();
  }

  void hide(String key) {
    hidden.add(key);
    notifyListeners();
  }

  void unhideAll() {
    hidden.clear();
    notifyListeners();
  }
}
