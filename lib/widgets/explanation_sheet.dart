import 'package:flutter/material.dart';

class SheetAction {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const SheetAction(this.label, this.onTap, {this.primary = false});
}

/// Every DSS card feeds this same structure: result, method, data, limitation.
class ExplanationData {
  final String title;
  final String result;
  final String method;
  final String limitation;
  final List<MapEntry<String, String>> rows;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;
  final List<SheetAction> actions;

  const ExplanationData({
    required this.title,
    required this.result,
    required this.method,
    required this.limitation,
    this.rows = const [],
    this.seeAllLabel,
    this.onSeeAll,
    this.actions = const [],
  });
}

Future<void> showExplanationSheet(BuildContext context, ExplanationData data) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _ExplanationSheet(data: data),
  );
}

class _ExplanationSheet extends StatelessWidget {
  final ExplanationData data;
  const _ExplanationSheet({required this.data});

  static const _muted = Color(0xFF5B6663);
  static const _border = Color(0xFFE6E2D8);

  Widget _section(String label, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _muted)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _section('HASIL', data.result),
            const SizedBox(height: 16),
            _section('CARA HITUNG', data.method),
            if (data.rows.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('DATA YANG DIPAKAI',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: _muted)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    for (final r in data.rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(r.key,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text(r.value,
                                style: const TextStyle(
                                    fontSize: 13, color: _muted)),
                          ],
                        ),
                      ),
                    if (data.onSeeAll != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            data.onSeeAll!();
                          },
                          child: Text(data.seeAllLabel ?? 'Lihat semua'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _section('BATASAN', data.limitation),
            if (data.actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < data.actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _actionButton(context, data.actions[i])),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, SheetAction a) {
    void tap() {
      Navigator.pop(context);
      a.onTap();
    }

    const size = Size.fromHeight(48);
    return a.primary
        ? FilledButton(
            onPressed: tap,
            style: FilledButton.styleFrom(minimumSize: size),
            child: Text(a.label))
        : OutlinedButton(
            onPressed: tap,
            style: OutlinedButton.styleFrom(minimumSize: size),
            child: Text(a.label));
  }
}
