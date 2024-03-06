import 'package:flutter/material.dart';

class ConditionalDisplayWidget extends StatelessWidget {
  const ConditionalDisplayWidget({
    required this.show,
    required this.child,
    required this.placeholderText,
    required this.onPressed,
    super.key,
  });

  final bool show;
  final Widget child;
  final String placeholderText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (show) {
      return child;
    }
    return TextButton(
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      ),
      onPressed: onPressed,
      child: Text(
        placeholderText,
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.black,
        ),
      ),
    );
  }
}
