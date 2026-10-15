import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum NavTab { home, inventory, expenses, household }

/// Shared "+" sheet (moved out of InventoryListScreen so every tab can use it).
void showAddOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Scan struk'),
            subtitle: const Text('Isi otomatis dari foto struk'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/inventory/scan-receipt');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Tambah manual'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/inventory/add');
            },
          ),
        ],
      ),
    ),
  );
}

class AppAddFab extends StatelessWidget {
  const AppAddFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showAddOptions(context),
      tooltip: 'Tambah barang',
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 32),
    );
  }
}

class AppBottomBar extends StatelessWidget {
  final NavTab current;
  const AppBottomBar({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 68,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        children: [
          _item(context, NavTab.home, Icons.home_outlined, Icons.home, 'Beranda', '/dashboard'),
          _item(context, NavTab.inventory, Icons.inventory_2_outlined, Icons.inventory_2, 'Inventaris', '/inventory'),
          const SizedBox(width: 72),
          _item(context, NavTab.expenses, Icons.receipt_long_outlined, Icons.receipt_long, 'Pengeluaran', '/expenses'),
          _item(context, NavTab.household, Icons.groups_outlined, Icons.groups, 'Rumah', '/household'),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, NavTab tab, IconData icon, IconData active,
      String label, String route) {
    final selected = tab == current;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF5B6663);
    return Expanded(
      child: InkWell(
        onTap: selected ? null : () => context.go(route),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? active : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
