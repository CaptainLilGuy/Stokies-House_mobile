import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:homeventory/models/category.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';


class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>{
  final _nameCtrl = TextEditingController();
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isAdding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {_isLoading = true; _error = null; });
    try {
      final cats = await ApiService().getCategories();
      setState(() => _categories = cats);
    } catch (e) {
      setState(() => _error = 'Failed to load categories');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      await ApiService().addCategory(name);
      _nameCtrl.clear();
      await _loadCategories();
    } catch (e) {
      setState(() => _error = 'Failed to add category');
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Remove "$name"? Items in this category will be uncategorized.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().deleteCategory(id);
      await _loadCategories();
    } catch (e) {
      setState(() => _error = 'Failed to delete category');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
         icon: Icon(Icons.arrow_back),
         onPressed: () => context.go('/inventory/add'),
         ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'New Category Name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 8),
                _isAdding
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton.filled(
                      onPressed: _addCategory, 
                      icon: const Icon(Icons.add),
                      ),
              ],
            ),
          ),

          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? const Center(child: Text('No categories yet.'))
                    : ListView.builder(
                        itemCount:  _categories.length,
                        itemBuilder: (ctx, i) {
                          final cat = _categories[i];
                          return Slidable(
                            key: ValueKey(cat.id),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(), 
                              children: [
                                SlidableAction(
                                  onPressed: (_) => _deleteCategory(cat.id, cat.name),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete_outline,
                                  label: 'Delete',
                                  ),
                                ],
                              ),
                            child: ListTile(
                              title: Text(cat.name),
                              leading: const Icon(Icons.label_outline),
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