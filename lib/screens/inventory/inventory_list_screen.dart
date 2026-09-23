import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homeventory/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_item.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState(){
    super.initState();
    //Fetch on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchItems();
    });
  }

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
              onTap: () => context.go('/inventory/scan-receipt'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Enter manually'),
              onTap: () => context.go('/inventory/add'),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.go('/household'), 
            icon: const Icon(Icons.home_outlined)),
        ],
      ),
      body: Column(
        children: [
          //searchBar
          Padding(
            padding: const EdgeInsets.fromLTRB(16,12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: inv.setSearch,
              decoration: InputDecoration(
                hintText: 'Search Items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: inv.searchQuery.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      inv.setSearch('');
                    }, 
                    icon: const Icon(Icons.clear),)
                  : null,
              ),
            ),
          ),
          //Category filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal, 
              itemCount: inv.categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6,),
              itemBuilder: (ctx, i) {
                final cat = inv.categories[i];
                final selected = inv.selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => inv.setCategory(cat),
                );
              }, 
            ),
          ),
          const SizedBox(height: 8,),

          //list
          Expanded(
            child: inv.isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : inv.errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(inv.errorMessage!,
                                  style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: inv.fetchItems, 
                              child: const Text('Retry'),
                              ),
                          ],
                        ),
                      )
                    : inv.filtered.isEmpty 
                      ? const Center(
                        child: Text('No Items Found.',
                          style: TextStyle(color: Colors.green)))
                      : RefreshIndicator(
                          onRefresh: inv.fetchItems,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: inv.filtered.length,
                            itemBuilder: (ctx, i) => 
                              _ItemTile(item: inv.filtered[i]),
                            ),
                          ),
          ),
          ElevatedButton(
            onPressed: () async {
              const storage = FlutterSecureStorage();
              await storage.write(key: AppConstants.tokenKey, value: 'invalid_token');
              await storage.write(key: AppConstants.refreshTokenKey, value: 'invalid_refresh_token');
            },
            child: const Text('DEBUG: corrupt both tokens'),
          ),
        ],
      ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      //FAB to add item
    floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 50,),), 
    bottomNavigationBar: BottomAppBar(
      height: 56,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.go('/inventory'),
              icon: const Icon(Icons.home, size: 30),
            ),
            IconButton(
              onPressed: () => context.go('/inventory'),
              icon: const Icon(Icons.inventory, size: 30),
            ),
            const SizedBox(width: 60),
            IconButton(
              onPressed: () => context.go('/inventory'),
              icon: const Icon(Icons.receipt, size: 30),
            ),
            IconButton(
              onPressed: () => context.go('/household'),
              icon: const Icon(Icons.groups, size: 30),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final InventoryItem item;
  const _ItemTile({required this.item});

  bool get _isExpiringSoon {
    if (item.expiryDate == null) return false;
    return item.expiryDate!.difference(DateTime.now()).inDays <= 3; 
  }

  bool get _isExpired {
    if (item.expiryDate == null) return false;
    return item.expiryDate!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.read<InventoryProvider>();

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(), 
        children: [
          SlidableAction(
            onPressed: (_) async {
              final inventoryProvider = context.read<InventoryProvider>();

              await Future.delayed(const Duration(milliseconds: 300));
              if (!context.mounted) return;

              await _showRestockSheet(context, item);
              inventoryProvider.fetchItems();
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.add_box_outlined,
            label: 'Restock',
            ),
          SlidableAction(
            onPressed: (_) async {
              final confirmed = await showDialog<bool>(
                context: context, 
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete item?'),
                  content: Text('Remove "${item.name}" from inventory?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false), 
                      child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true), 
                      child: const Text('Delete')),
                  ],
                ),
              );
              if (confirmed == true) inv.deleteItem(item.id);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            )
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(item.name[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
          ),
          title: Text(item.name,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.quantity} ${item.unit}  ·  ${item.categoryName ?? 'Unrecognized'}'),
              if (item.expiryDate != null)
                Text(
                  _isExpired
                    ? 'Expired ${DateFormat('d MMM').format(item.expiryDate!)}'
                    : 'Expires ${DateFormat('d MMM').format(item.expiryDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isExpired
                        ? Colors.red
                        : _isExpiringSoon
                          ? Colors.orange
                          : Colors.grey,
                    fontWeight: _isExpiringSoon || _isExpired
                      ? FontWeight.w600
                      : FontWeight.normal,
                  ),
                ),
            ],
          ),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => context.push('/inventory/edit', extra: item),
        ),
      ),
    );
  }
}

Future<void> _showRestockSheet(BuildContext context, InventoryItem item) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _RestockSheetContent(item: item),
  );
}

class _RestockSheetContent extends StatefulWidget {
  final InventoryItem item;
  const _RestockSheetContent({required this.item});

  @override
  State<_RestockSheetContent> createState() => _RestockSheetContentState();
}

class _RestockSheetContentState extends State<_RestockSheetContent> {
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty == 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ApiService().restockItem(widget.item.id, qty, note: _noteCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = parseApiError(e);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Restock "${widget.item.name}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
          Text('Currently: ${widget.item.quantity} ${widget.item.unit}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Amount to add',
              suffixText: widget.item.unit,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Restock'),
            ),
          ),
        ],
      ),
    );
  }
}