import 'package:flutter/material.dart';

/// A custom navigation bar widget for navigation.
class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar(
    this.currentIndex,
    this.onIndexChanged, {
    super.key,
  });

  /// The index of the currently selected item.
  final int currentIndex;

  /// A callback function to invoke when the selection changes.
  final void Function(int) onIndexChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      height: 55.0,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            blurRadius: 30.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
        borderRadius: BorderRadius.circular(50.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIconWidget("Home", Icons.home, 0),
          _buildIconWidget("Camera", Icons.camera, 1),
          _buildIconWidget("Settings", Icons.settings, 2),
        ],
      ),
    );
  }

  Widget _buildIconWidget(String title, IconData icon, int index) {
    return Expanded(
      child: TextButton(
        onPressed: () {
          onIndexChanged(index);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.0,
              color: index == currentIndex ? Colors.blue : Colors.black87,
            ),
            const SizedBox(width: 10.0),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15.0,
                color: index == currentIndex ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
