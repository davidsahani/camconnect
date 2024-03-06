import 'package:flutter/material.dart';

void showSnackBarMessage(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Container(
          constraints: BoxConstraints(
            // make scaffold happy, it complains when snackbar goes off screen.
            maxHeight: MediaQuery.of(context).size.height - 78.0,
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15.0,
            ),
          ),
        ),
        backgroundColor: Colors.blue.shade50,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: const EdgeInsets.all(9.0),
        margin: const EdgeInsets.only(bottom: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
    );
}

void showSnackBarPrompt(
  BuildContext context,
  String message,
  String buttonText,
  VoidCallback onPressed, {
  bool dismissible = true,
  Duration duration = const Duration(days: 1),
}) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15.0,
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            )
          ],
        ),
        dismissDirection:
            dismissible ? DismissDirection.down : DismissDirection.none,
        duration: duration,
        backgroundColor: Colors.blue.shade50,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.all(9.0),
        margin: const EdgeInsets.only(bottom: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
    );
}
