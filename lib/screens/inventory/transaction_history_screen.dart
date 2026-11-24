import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_entry.dart';
import '../../services/api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const _pageSize = 30;
  static const Map<String?, String> _filters = {
    null: 'Semua',
    'purchased': 'Dibeli',
    'restocked': 'Restock',
    'consumed': 'Terpakai',
    'wasted': 'Dibuang',
    'adjusted': 'Penyesuaian',
  };

  final _scroll = ScrollController();
  List<TransactionEntry> _entries = [];
  int _total = 0;
  int _gen = 0; // bumps on every refresh so stale responses are dropped
  bool _loading = false;
  bool _loadingMore = false;
  String? _filter;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
    _refresh();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    final gen = ++_gen;
    setState(() {
      _loading = !silent;
      _error = null;
    });
    try {
      final data = await ApiService().getTransactionHistory(
          limit: _pageSize, offset: 0, changeType: _filter);
      debugPrint('history count=${data['count']} results=${(data['results'] as List).length}');
      if (!mounted || gen != _gen) return;
      setState(() {
        _entries = _parse(data);
        _total = data['count'] as int;
      });
    } catch (e) {
      if (!mounted || gen != _gen) return;
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted && gen == _gen) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _entries.length >= _total) return;
    final gen = _gen;
    setState(() => _loadingMore = true);
    try {
      final data = await ApiService().getTransactionHistory(
          limit: _pageSize, offset: _entries.length, changeType: _filter);
      if (!mounted || gen != _gen) return;
      setState(() {
        _entries = [..._entries, ..._parse(data)];
        _total = data['count'] as int;
      });
    } catch (e) {
      if (mounted && gen == _gen) setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<TransactionEntry> _parse(Map<String, dynamic> data) =>
      (data['results'] as List)
          .map((j) => TransactionEntry.fromJson(Map<String, dynamic>.from(j)))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.push('/inventory'),
        ),
        ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final f = _filters.entries.elementAt(i);
                return ChoiceChip(
                  label: Text(f.value),
                  selected: _filter == f.key,
                  onSelected: (_) {
                    if (_filter == f.key) return;
                    setState(() => _filter = f.key);
                    _refresh();
                  },
                );
              },
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _refresh, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(
          child: Text('Belum ada transaksi.', style: TextStyle(color: Colors.grey)));
    }
    final hasMore = _entries.length < _total;
    return RefreshIndicator(
      onRefresh: () => _refresh(silent: true),
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _entries.length + (hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final e = _entries[i];
          final prev = i > 0 ? _entries[i - 1] : null;
          final newDay = prev == null || !_sameDay(prev.createdAt, e.createdAt);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (newDay)
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 12, 0, 6),
                  child: Text(DateFormat('EEEE, d MMM yyyy').format(e.createdAt),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B6663))),
                ),
              _EntryTile(entry: e),
            ],
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

String _fmt(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

({IconData icon, Color color, String label}) _meta(String type) => switch (type) {
      'purchased' => (icon: Icons.shopping_bag_outlined, color: Colors.teal, label: 'Dibeli'),
      'restocked' => (icon: Icons.add_box_outlined, color: Colors.green, label: 'Restock'),
      'consumed' => (icon: Icons.remove_circle_outline, color: Colors.orange, label: 'Terpakai'),
      'wasted' => (icon: Icons.delete_outline, color: Colors.red, label: 'Dibuang'),
      _ => (icon: Icons.tune, color: Colors.blueGrey, label: 'Penyesuaian'),
    };

class _EntryTile extends StatelessWidget {
  final TransactionEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final m = _meta(e.changeType);
    final positive = e.delta > 0;
    final rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final meta = <String>[
      m.label,
      if (e.username != null) 'oleh ${e.username}' else if (e.source == 'auto') 'otomatis',
      if (e.source == 'ocr') 'OCR struk',
      DateFormat('HH:mm').format(e.createdAt),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: m.color.withValues(alpha: 0.15),
              child: Icon(m.icon, color: m.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(meta, style: const TextStyle(fontSize: 12, color: Color(0xFF5B6663))),
                  if (e.unitPrice != null)
                    Text('@ ${rp.format(e.unitPrice)} / ${e.itemUnit}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5B6663))),
                  if (e.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(e.note,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${positive ? '+' : '−'}${_fmt(e.delta.abs())} ${e.itemUnit}',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: positive ? Colors.green.shade700 : Colors.red.shade700)),
          ],
        ),
      ),
    );
  }
}