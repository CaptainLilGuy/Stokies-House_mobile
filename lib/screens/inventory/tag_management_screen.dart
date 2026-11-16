import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../models/tag.dart';
import '../../providers/inventory_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/tag_name_dialog.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final _nameCtrl = TextEditingController();
  List<Tag> _tags = [];
  bool _isLoading = false;
  bool _isAdding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _refreshInventory() => context.read<InventoryProvider>().fetchItems();

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tags = await ApiService().getTags();
      if (mounted) setState(() => _tags = tags);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memuat tag');
    } finally {
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  Future<void> _addTag() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isAdding = true;
      _error = null;
    });
    try {
      await ApiService().addTag(name);
      _nameCtrl.clear();
      await _loadTags();
    } catch (e) {
      if (mounted) setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _renameTag(Tag tag) async {
    final name = await showTagNameDialog(context, 
      title: 'Ubah nama tag', initial: tag.name, confirmLabel: 'Simpan');
    if (name == null || name == tag.name || !mounted) return;
    try {
      await ApiService().renameTag(tag.id, name);
      await _loadTags();
    } catch (e) {
      if (mounted) setState(() => _error = parseApiError(e));
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tag?'),
        content: Text(
          'Hapus "${tag.name}"? Tag akan dilepas dari ${tag.itemCount} barang. '
          'Barangnya sendiri tidak ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiService().deleteTag(tag.id);
      await _loadTags();
      if (mounted) _refreshInventory();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal menghapus tag');
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tag')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      hintText: 'Nama tag baru',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                _isAdding
                  ? const Padding(
                    padding: EdgeInsets.all(12), 
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : IconButton.filled(
                    onPressed: _addTag, 
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),  
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, 
              style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tags.isEmpty
                ? const Center(child: Text('Belum ada tag'))
                : ListView.builder(
                  itemCount: _tags.length,
                  itemBuilder: (ctx, i) {
                    final tag = _tags[i];
                    return Slidable(
                      key: ValueKey(tag.id),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(), 
                        children: [
                          SlidableAction(
                            onPressed: (_) => _deleteTag(tag),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_outline,
                            label: 'Hapus',
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.sell_outlined),
                        title: Text(tag.name),
                        subtitle: Text('${tag.itemCount} barang'),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () => _renameTag(tag),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );  
  }
}

