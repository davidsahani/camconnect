import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableTextBox extends StatefulWidget {
  const EditableTextBox({
    super.key,
    this.hintText,
    required this.text,
    required this.prefixText,
    required this.onSubmitted,
    this.onChanged,
    this.errorChecker,
  });

  final String text;
  final String? hintText;
  final String prefixText;
  final void Function(String)? onChanged;
  final void Function(String) onSubmitted;
  final String? Function(String)? errorChecker;

  @override
  State<EditableTextBox> createState() => _EditableTextBoxState();
}

class _EditableTextBoxState extends State<EditableTextBox> {
  bool _isEditable = false;
  String? _errorText;
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

  void _handleKeyPress(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _isEditable = false);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyPress,
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: _isEditable,
            onChanged: widget.onChanged,
            onSubmitted: _handleSubmitted,
            style: const TextStyle(
              color: Colors.black,
            ),
            decoration: InputDecoration(
              errorText: _errorText,
              hintText: widget.hintText,
              prefixIcon: Text(
                widget.prefixText,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
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
      ]),
    );
  }
}
