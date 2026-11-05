import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/tag.dart';
import '../services/api_service.dart';
import 'tag_name_dialog.dart';

class TagSelector extends StatefulWidget {
  final List<Tag> selected;
  final ValueChanged<List<Tag>> onChanged;

  const TagSelector({super.key, required this.selected, required this.onChanged});

  @override 
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  List<Tag> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _byName(Tag a, Tag b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

  Future<void> _load({bool syncSelection = false}) async {
    try {
      final tags = await ApiService().getTags();
      if (!mounted) return;
      setState(() {
        _all = tags;
        _loading = false;
        _error = null;
      });
      if (syncSelection) {
        final fresh = <Tag>[];
        for (final s in widget.selected) {
          final match = tags.where((t) => t.id == s.id);
          if (match.isNotEmpty) fresh.add(match.first);
        }
        widget.onChanged(fresh);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load tags';
      });
    }
  }

  bool _isSelected(Tag t) => widget.selected.any((s) => s.id == t.id);

  void _toggle(Tag t, bool on) async {
    final next = widget.selected.where((s) => s.id != t.id).toList();
    if (on) next.add(t);
    widget.onChanged(next);
  }

  Future<void> _createTag() async {
    final name = await showTagNameDialog(context, 
      title: 'New Tag', confirmLabel: 'Create');
    if (name == null || !mounted) return;

    final existing = 
      _all.where((t) => t.name.toLowerCase() == name.toLowerCase()).firstOrNull;
    if (existing != null) {
      if (!_isSelected(existing)) _toggle(existing, true);
      return;
    }

    try {
      final tag = await ApiService().addTag(name);
      if (!mounted) return;
      setState(() => _all = [..._all, tag]..sort(_byName));
      _toggle(tag, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(parseApiError(e))));
    }
  }

  Future<void> _manage() async {
    await context.push('/inventory/tags');
    if (mounted) _load(syncSelection: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for(final t in _all)
              FilterChip(
                label: Text(t.name),
                selected: _isSelected(t), 
                onSelected: (on) => _toggle(t, on),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('New Tag'),
              onPressed: _createTag,
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _manage, 
            icon: const Icon(Icons.sell_outlined, size: 18),
            label: const Text('Manage Tags')),
        ),
      ],
    );
  }
}