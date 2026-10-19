import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  void _showAddOptions(BuildContext context) {
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
              title: const Text('Scan Receipt'),
              subtitle: const Text('Auto-fill from a photo of a receipt'),
              onTap: () {
                Navigator.pop(ctx); // close the sheet first
                context.push('/inventory/scan-receipt');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Enter manually'),
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

  Widget _navItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final selected = navigationShell.currentIndex == index;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;
    return IconButton(
      tooltip: label,
      icon: Icon(selected ? activeIcon : icon, size: 30, color: color),
      onPressed: () => navigationShell.goBranch(
        index,
        // tapping the active tab again returns to that tab's root
        initialLocation: index == navigationShell.currentIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 40),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 56,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(context, 0, Icons.inventory_2_outlined, Icons.inventory_2, 'Inventory'),
              _navItem(context, 1, Icons.receipt_long_outlined, Icons.receipt_long, 'Expenses'),
              const SizedBox(width: 60), // gap for the FAB
              _navItem(context, 2, Icons.groups_outlined, Icons.groups, 'Household'),
            ],
          ),
        ),
      ),
    );
  }
}