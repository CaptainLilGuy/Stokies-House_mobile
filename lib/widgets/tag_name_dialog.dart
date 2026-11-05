import 'package:flutter/material.dart';

Future<String?> showTagNameDialog(
  BuildContext context, {
    required String title,
    String initial = '',
    String confirmLabel = '',
  }) {
    return showDialog(
      context: context, 
      builder: (_) => _TagNameDialog(
        title: title, initial: initial, confirmLabel: confirmLabel
      ),
    );
  }

class _TagNameDialog extends StatefulWidget {
    final String title, initial, confirmLabel;
    const _TagNameDialog(
      { required this.title, required this.initial, required this.confirmLabel});
    
    @override 
    State<_TagNameDialog> createState() => _TagNameDialogState();
}

class _TagNameDialogState extends State<_TagNameDialog> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(){
    final name = _ctrl.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (name.isEmpty){
      setState(() => _error = 'Tag name is required');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLength: 300, //SAMAIN KAYAK DI BACKEND
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'e.g. kulkas, dapur, dipakai dulu',
          border: const OutlineInputBorder(),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }

}