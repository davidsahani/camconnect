import 'package:flutter/material.dart';

void showSnackBarMessage(
  BuildContext context,
  String message, {
  bool keepAboveNavBar = true,
  Duration duration = const Duration(seconds: 2),
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
            style: const TextStyle(color: Colors.black, fontSize: 15.0),
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin:
            EdgeInsets.fromLTRB(10.0, 0.0, 10.0, keepAboveNavBar ? 75.0 : 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
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
  bool keepAboveNavBar = true,
  Duration duration = const Duration(seconds: 5),
}) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Column(
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15.0,
              ),
            ),
            const SizedBox(height: 20.0),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            )
          ],
        ),
        dismissDirection:
            dismissible ? DismissDirection.down : DismissDirection.none,
        duration: duration,
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin:
            EdgeInsets.fromLTRB(10.0, 0.0, 10.0, keepAboveNavBar ? 75.0 : 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
}
