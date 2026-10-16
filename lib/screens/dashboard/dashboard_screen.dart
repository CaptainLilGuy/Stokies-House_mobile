import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/explanation_sheet.dart';

// Palette from the hi-fi mockup
const _bg = Color(0xFFF5F3EE);
const _border = Color(0xFFE6E2D8);
const _muted = Color(0xFF5B6663);
const _ink = Color(0xFF1F2A28);
const _warnBg = Color(0xFFFDEFD6);
const _warnFg = Color(0xFF8A4B08);
const _warnBar = Color(0xFFB45309);
const _dangerBg = Color(0xFFFDE6E3);
const _dangerFg = Color(0xFFA3261C);

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bln = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _blnFull = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

final _rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
String _short(DateTime d) => '${d.day} ${_bln[d.month - 1]}';
String _qty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

enum UsageKind { used, partial, wasted }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetch();
      final hp = context.read<HouseholdProvider>();
      if (hp.status == HouseholdStatus.idle) hp.fetchHousehold();
    });
  }

  // ── actions ─────────────────────────────────────────────
  Future<void> _act(InventoryItem item, UsageKind kind) async {
    final dp = context.read<DashboardProvider>();
    final inv = context.read<InventoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    double? qty = item.quantity;
    if (kind == UsageKind.partial) {
      qty = await _askPartialQty(item);
      if (qty == null) return;
    }
    final err = await dp.logUsage(item, wasted: kind == UsageKind.wasted, qty: qty);
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? 'Tercatat: ${item.name}'),
    ));
    if (err == null) inv.fetchItems();
  }

  Future<double?> _askPartialQty(InventoryItem item) {
    final ctrl = TextEditingController();
    String? error;
    return showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Berapa yang terpakai?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tersisa ${_qty(item.quantity)} ${item.unit}',
                  style: const TextStyle(color: _muted)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixText: item.unit,
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                if (v == null || v <= 0) {
                  setLocal(() => error = 'Masukkan jumlah yang valid');
                } else if (v > item.quantity) {
                  setLocal(() => error = 'Melebihi stok (${_qty(item.quantity)})');
                } else {
                  Navigator.pop(ctx, v);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBudget() async {
    final dp = context.read<DashboardProvider>();
    final ctrl = TextEditingController(
        text: dp.budget == null ? '' : dp.budget!.toStringAsFixed(0));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Budget bulanan'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
              prefixText: 'Rp ', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (value != null) await dp.setBudget(value);
  }

  void _explainSpending(DashboardProvider dp) {
    final n = DateTime.now();
    final rows = dp.monthExpenses.take(4).map((e) => MapEntry(
        e.description,
        '${e.source == 'ocr' ? 'OCR struk' : 'Manual'} · ${_rp.format(e.amount)}')).toList();
    final usedPct = (dp.spentFraction * 100).round();
    final pacePct = (dp.paceFraction * 100).round();
    showExplanationSheet(
      context,
      ExplanationData(
        title: 'Pengeluaran ${_blnFull[n.month - 1]}',
        result: '$usedPct% budget terpakai pada hari ke-${dp.dayOfMonth}, laju normal $pacePct%.',
        method:
            'Total pengeluaran 1–${dp.dayOfMonth} ${_bln[n.month - 1]} ÷ budget bulanan. '
            'Peringatan muncul bila persentase terpakai melebihi persentase hari berjalan '
            '+ ${DashboardProvider.paceMarginPoints} poin, dan baru dinilai mulai hari ke-${DashboardProvider.warnFromDay}.',
        rows: rows,
        seeAllLabel: 'Lihat semua ${dp.monthExpenses.length} transaksi',
        onSeeAll: dp.monthExpenses.length > rows.length ? () => context.go('/expenses') : null,
        limitation:
            'Hanya mencakup pengeluaran yang tercatat di aplikasi. Belanja besar di awal bulan bisa memicu peringatan lebih cepat.',
        actions: [
          SheetAction('Ubah budget', _editBudget, primary: true),
          SheetAction('Sembunyikan insight', () => dp.hide('spending')),
        ],
      ),
    );
  }

  void _explainPattern(DashboardProvider dp) {
    showExplanationSheet(
      context,
      ExplanationData(
        title: 'Pola pemakaian',
        result: 'Barang yang paling sering kamu catat terpakai bulan ini.',
        method:
            'Menghitung berapa kali tiap barang dicatat "Terpakai" atau "Sebagian". '
            'Pola dibuka setelah ${DashboardProvider.unlockLogCount} catatan agar tidak menyesatkan.',
        rows: [for (final u in dp.topUsed) MapEntry(u.name, '${u.count} kali')],
        limitation:
            'Bersifat deskriptif, bukan prediksi. Hanya mencakup pemakaian yang dicatat manual.',
      ),
    );
  }

  // ── build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DashboardProvider>();
    final hp = context.watch<HouseholdProvider>();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const AppAddFab(),
      bottomNavigationBar: const AppBottomBar(current: NavTab.home),
      body: SafeArea(
        child: dp.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => dp.fetch(silent: true),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    _header(hp, now),
                    const SizedBox(height: 16),
                    if (hp.status == HouseholdStatus.loaded && !hp.hasHousehold) ...[
                      _setupHouseholdCard(),
                      const SizedBox(height: 14),
                    ],
                    _quickAdd(),
                    const SizedBox(height: 14),
                    if (dp.errorMessage != null) ...[
                      _errorCard(dp),
                      const SizedBox(height: 14),
                    ],
                    _actionsCard(dp),
                    if (!dp.hidden.contains('spending')) ...[
                      const SizedBox(height: 14),
                      _spendingCard(dp, now),
                    ],
                    const SizedBox(height: 14),
                    _priceCard(dp),
                    const SizedBox(height: 14),
                    _patternCard(dp),
                    const SizedBox(height: 14),
                    _wasteCard(dp),
                    if (dp.hidden.isNotEmpty)
                      TextButton(
                          onPressed: dp.unhideAll,
                          child: const Text('Tampilkan insight yang disembunyikan')),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header(HouseholdProvider hp, DateTime now) {
    final name = hp.household?.name;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name == null ? 'Halo!' : 'Halo, $name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
              Text('${_hari[now.weekday - 1]}, ${now.day} ${_bln[now.month - 1]} ${now.year}',
                  style: const TextStyle(fontSize: 13, color: _muted)),
            ],
          ),
        ),
        // Bell intentionally omitted until FCM notifications exist.
      ],
    );
  }

  Widget _quickAdd() => Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => context.push('/inventory/scan-receipt'),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan struk'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/inventory/add'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Tambah manual'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
        ],
      );

  Widget _setupHouseholdCard() => _Card(
        label: 'MULAI DI SINI',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buat atau gabung rumah tangga',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Inventaris dan pengeluaran disimpan per rumah tangga.',
                style: TextStyle(fontSize: 13, color: _muted)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/household'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Atur rumah tangga'),
            ),
          ],
        ),
      );

  Widget _errorCard(DashboardProvider dp) => _Card(
        label: 'GAGAL MEMUAT',
        child: Row(
          children: [
            Expanded(
                child: Text(dp.errorMessage!, style: const TextStyle(color: _dangerFg))),
            TextButton(onPressed: () => dp.fetch(), child: const Text('Coba lagi')),
          ],
        ),
      );

  // ── card 1 ──────────────────────────────────────────────
  Widget _actionsCard(DashboardProvider dp) {
    const label = '1 · PERLU TINDAKAN HARI INI';
    if (dp.expiring.isEmpty) {
      return _Card(
        label: label,
        child: const _EmptyRow(
          icon: Icons.check_circle_outline,
          title: 'Semua aman hari ini',
          body: 'Tidak ada barang yang kedaluwarsa dalam 3 hari ke depan.',
        ),
      );
    }
    final shown = dp.expiring.take(3).toList();
    return _Card(
      label: label,
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            _ActionItem(item: shown[i], onAct: (k) => _act(shown[i], k)),
            if (i < shown.length - 1)
              const Divider(height: 28, color: Color(0xFFEEEBE3)),
          ],
          if (dp.expiring.length > shown.length)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.go('/inventory'),
                child: Text('Lihat ${dp.expiring.length - shown.length} lainnya'),
              ),
            ),
        ],
      ),
    );
  }

  // ── card 2 ──────────────────────────────────────────────
  Widget _spendingCard(DashboardProvider dp, DateTime now) {
    final label = '2 · PENGELUARAN ${_blnFull[now.month - 1].toUpperCase()}';
    final status = dp.spendStatus;
    if (status == SpendStatus.noBudget) {
      return _Card(
        label: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _EmptyRow(
              icon: Icons.receipt_long_outlined,
              title: 'Atur budget bulanan',
              body: 'Tentukan batas belanja agar aplikasi bisa membandingkan laju pengeluaranmu.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _editBudget,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Atur budget'),
            ),
          ],
        ),
      );
    }
    late final Color barColor;
    late final String text;
    Color textColor = _warnFg;
    switch (status) {
      case SpendStatus.overBudget:
        barColor = _dangerFg; text = 'Melebihi budget'; textColor = _dangerFg;
      case SpendStatus.fasterThanUsual:
        barColor = _warnBar; text = 'Lebih cepat dari biasanya';
      case SpendStatus.tooEarly:
        barColor = Theme.of(context).colorScheme.primary;
        text = 'Masih awal bulan'; textColor = _muted;
      default:
        barColor = Theme.of(context).colorScheme.primary;
        text = 'Sesuai laju normal'; textColor = Theme.of(context).colorScheme.primary;
    }
    return _Card(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(_rp.format(dp.spent),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              Text('dari ${_rp.format(dp.budget!)}',
                  style: const TextStyle(fontSize: 13, color: _muted)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (ctx, box) {
            final w = box.maxWidth;
            return SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 4, left: 0, right: 0,
                    child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE4E0D6),
                            borderRadius: BorderRadius.circular(5))),
                  ),
                  Positioned(
                    top: 4, left: 0,
                    child: Container(
                        height: 10,
                        width: w * dp.spentFraction.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                            color: barColor, borderRadius: BorderRadius.circular(5))),
                  ),
                  Positioned(
                    top: 0,
                    left: (w * dp.paceFraction).clamp(0.0, w - 3),
                    child: Container(
                        width: 3, height: 18,
                        decoration: BoxDecoration(
                            color: _ink, borderRadius: BorderRadius.circular(2))),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          Text('Hari ke-${dp.dayOfMonth} dari ${dp.daysInMonth} · garis hitam = laju normal (${(dp.paceFraction * 100).round()}%)',
              style: const TextStyle(fontSize: 13, color: _muted)),
          _InfoLink('Lihat perhitungan', () => _explainSpending(dp)),
        ],
      ),
    );
  }

  // ── card 3  ──────────────────────────────────────────────
Widget _priceCard(DashboardProvider dp) {
    const label = '3 · HARGA BERUBAH';
    if (dp.priceChanges.isEmpty) {
      return _Card(
        label: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _EmptyRow(
              icon: Icons.info_outline,
              title: 'Belum ada perubahan harga',
              body: 'Muncul setelah barang yang sama dibeli dua kali atau lebih dengan harga tercatat.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/inventory/scan-receipt'),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan struk'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      );
    }
    final p = dp.priceChanges.first;
    final up = p.changePct > 0;
    return _Card(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.name}${p.unit.isEmpty ? '' : ' (${p.unit})'}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('${_rp.format(p.lastPrice)} · ${_short(p.lastDate)}\n'
                        'Rata-rata ${p.baselineCount} pembelian terakhir ${_rp.format(p.baselinePrice)}',
                        style: const TextStyle(fontSize: 13, color: _muted, height: 1.45)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: up ? _dangerBg : const Color(0xFFE3F1EC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${up ? '▲' : '▼'} ${p.changePct.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: up ? _dangerFg : Theme.of(context).colorScheme.primary)),
              ),
            ],
          ),
          _InfoLink(
              dp.priceChanges.length > 1
                  ? 'Lihat ${dp.priceChanges.length} perubahan harga'
                  : 'Lihat perhitungan',
              () => _explainPrice(dp)),
        ],
      ),
    );
  }

  void _explainPrice(DashboardProvider dp) {
    showExplanationSheet(
      context,
      ExplanationData(
        title: 'Perubahan harga',
        result: '${dp.priceChanges.length} barang berubah harga lebih dari 10% dari biasanya.',
        method:
            'Harga pembelian terakhir dibandingkan dengan rata-rata hingga 3 pembelian '
            'sebelumnya dari barang yang sama. Hanya barang yang dibeli dalam 30 hari terakhir '
            'dan berubah minimal 10% yang ditampilkan.',
        rows: [
          for (final p in dp.priceChanges)
            MapEntry(p.name,
                '${_rp.format(p.baselinePrice)} → ${_rp.format(p.lastPrice)} '
                '(${p.changePct > 0 ? '▲' : '▼'}${p.changePct.abs().toStringAsFixed(0)}%)'),
        ],
        limitation:
            'Hanya memakai pembelian yang harganya tercatat. Perbandingan akurat bila satuan barang '
            'sama di setiap pembelian (misalnya selalu kg).',
      ),
    );
  }

  // ── card 4 ──────────────────────────────────────────────
  Widget _patternCard(DashboardProvider dp) {
    if (!dp.patternUnlocked) {
      final n = dp.usageLogCount.clamp(0, DashboardProvider.unlockLogCount);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBDB7A8), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('4 · POLA PEMAKAIAN'),
            Row(
              children: [
                const Expanded(
                  child: Text('Catat pemakaian 5 kali untuk membuka pola ini',
                      style: TextStyle(fontSize: 15)),
                ),
                const Icon(Icons.lock_outline, color: _muted),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < DashboardProvider.unlockLogCount; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: i < n
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFDAD5C8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text('$n dari ${DashboardProvider.unlockLogCount} catatan',
                style: const TextStyle(fontSize: 13, color: _muted)),
          ],
        ),
      );
    }
    return _Card(
      label: '4 · POLA PEMAKAIAN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paling sering terpakai',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          for (final u in dp.topUsed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(u.name),
                  Text('${u.count} kali', style: const TextStyle(color: _muted)),
                ],
              ),
            ),
          _InfoLink('Lihat perhitungan', () => _explainPattern(dp)),
        ],
      ),
    );
  }

  // ── card 5 (count only until unit price exists) ─────────
  Widget _wasteCard(DashboardProvider dp) {
    final now = DateTime.now();
    final label = '5 · TERBUANG BULAN INI';
    if (dp.wastedThisMonth == 0) {
      return _Card(
        label: label,
        child: const _EmptyRow(
          icon: Icons.check_circle_outline,
          title: 'Belum ada yang dibuang',
          body: 'Pertahankan! Setiap kali kamu menekan "Dibuang", jumlahnya muncul di sini.',
        ),
      );
    }
    String? trend;
    if (dp.wasteLastValue > 0 && dp.wasteValue > 0) {
      final diff = ((dp.wasteValue - dp.wasteLastValue) / dp.wasteLastValue * 100).round();
      trend = diff <= 0 ? 'Turun ${diff.abs()}% dari bulan lalu' : 'Naik $diff% dari bulan lalu';
    }
    final hasValue = dp.wasteValue > 0;
    return _Card(
      label: '$label (${_bln[now.month - 1].toUpperCase()})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(hasValue ? _rp.format(dp.wasteValue) : '${dp.wastedThisMonth} kali',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              Text(hasValue
                      ? '${dp.wastedThisMonth} kali · bulan lalu ${_rp.format(dp.wasteLastValue)}'
                      : 'bulan lalu ${dp.wastedLastMonth}',
                  style: const TextStyle(fontSize: 13, color: _muted)),
            ],
          ),
          if (trend != null)
            Text(trend, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: trend.startsWith('Turun') ? Theme.of(context).colorScheme.primary : _warnFg)),
          if (dp.wasteUnvalued > 0)
            Text('${dp.wasteUnvalued} catatan belum punya harga, jadi tidak dihitung dalam nilai.',
                style: const TextStyle(fontSize: 13, color: _muted)),
          if (dp.wasteItems.isNotEmpty) _InfoLink('Lihat item', () => _explainWaste(dp)),
        ],
      ),
    );
  }
  void _explainWaste(DashboardProvider dp) {
    showExplanationSheet(
      context,
      ExplanationData(
        title: 'Terbuang bulan ini',
        result: '${_rp.format(dp.wasteValue)} dari ${dp.wastedThisMonth} catatan "Dibuang".',
        method:
            'Jumlah yang dibuang × harga pembelian terakhir barang itu sebelum dibuang.',
        rows: [
          for (final i in dp.wasteItems)
            MapEntry(i.name, '${_qty(i.quantity)} ${i.unit} · ${_rp.format(i.value)}'),
        ],
        limitation:
            'Catatan tanpa harga pembelian tidak dihitung nilainya. Harga bisa berbeda dari harga '
            'sebenarnya barang yang dibuang.',
      ),
    );
  }
}

// ── small shared widgets ──────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _muted)),
      );
}

class _Card extends StatelessWidget {
  final String label;
  final Widget child;
  const _Card({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_Label(label), child],
        ),
      );
}

class _EmptyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _EmptyRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 13, color: _muted, height: 1.45)),
              ],
            ),
          ),
        ],
      );
}

class _InfoLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _InfoLink(this.text, this.onTap);

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.info_outline, size: 18),
        label: Text(text),
        style: TextButton.styleFrom(
            minimumSize: const Size(0, 44), padding: EdgeInsets.zero),
      );
}

class _ActionItem extends StatelessWidget {
  final InventoryItem item;
  final void Function(UsageKind) onAct;
  const _ActionItem({required this.item, required this.onAct});

  @override
  Widget build(BuildContext context) {
    final left = DashboardProvider.daysLeft(item);
    final String badge;
    final bool urgent = left <= 1;
    if (left < 0) {
      badge = 'lewat ${-left} hari';
    } else if (left == 0) {
      badge = 'hari ini';
    } else if (left == 1) {
      badge = 'besok';
    } else {
      badge = '$left hari';
    }
    Widget btn(String t, UsageKind k) => Expanded(
          child: OutlinedButton(
            onPressed: () => onAct(k),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: urgent ? _dangerBg : _warnBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(badge,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: urgent ? _dangerFg : _warnFg)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('${_qty(item.quantity)} ${item.unit} · Kedaluwarsa ${_short(item.expiryDate!)}',
            style: const TextStyle(fontSize: 13, color: _muted)),
        const SizedBox(height: 10),
        Row(children: [
          btn('Terpakai', UsageKind.used),
          const SizedBox(width: 8),
          btn('Sebagian', UsageKind.partial),
          const SizedBox(width: 8),
          btn('Dibuang', UsageKind.wasted),
        ]),
      ],
    );
  }
}
