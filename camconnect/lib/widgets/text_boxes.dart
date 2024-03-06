import 'package:flutter/material.dart';

class TextBox extends StatelessWidget {
  const TextBox({
    super.key,
    required this.text,
    required this.prefixText,
    required this.onPressed,
  });

  final String text;
  final String prefixText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          enabled: false,
          controller: TextEditingController(text: text),
          style: const TextStyle(
            color: Colors.black,
          ),
          decoration: InputDecoration(
            prefixText: prefixText,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.settings_input_antenna_rounded),
        onPressed: onPressed,
      ),
    ]);
  }
}

class EditableTextBox extends StatefulWidget {
  const EditableTextBox({
    super.key,
    required this.text,
    required this.prefixText,
    required this.onSubmitted,
    this.errorChecker,
  });

  final String text;
  final String prefixText;
  final void Function(String) onSubmitted;
  final String? Function(String)? errorChecker;

  @override
  State<EditableTextBox> createState() => _EditableTextBoxState();
}

class _EditableTextBoxState extends State<EditableTextBox> {
  String? _errorText;
  bool _isEditable = false;
  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.text;
  }

  @override
  void didUpdateWidget(covariant EditableTextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.text = widget.text;
      _errorText = null;
      _isEditable = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String value) {
    setState(() {
      _errorText = widget.errorChecker?.call(value);
    });
    if (_errorText == null) {
      _isEditable = false;
      _focusNode.unfocus();
      widget.onSubmitted(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          focusNode: _focusNode,
          controller: _controller,
          enabled: _isEditable,
          onSubmitted: _handleSubmitted,
          style: const TextStyle(
            color: Colors.black,
          ),
          decoration: InputDecoration(
            prefixText: widget.prefixText,
            errorText: _errorText,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          setState(() => _isEditable = !_isEditable);

          if (_isEditable) {
            FocusScope.of(context).requestFocus(_focusNode);
          } else {
            _focusNode.unfocus();
          }
        },
      ),
    ]);
  }
}
