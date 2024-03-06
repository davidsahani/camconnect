import 'package:flutter/material.dart';

import 'custom_indexed_stack.dart';

/// A custom implementation of a page view with horizontal swipe gesture support.
///
/// Allows navigating through a list of children widgets using horizontal swipes.
class CustomPageView extends StatelessWidget {
  const CustomPageView({
    super.key,
    required this.currentPage,
    required this.children,
    required this.onPageChanged,
  });

  /// The index of the currently visible page.
  final int currentPage;

  /// The list of widgets representing individual pages.
  final List<Widget> children;

  /// A callback function to invoke when the page changes.
  final void Function(int) onPageChanged;

  /// Handles the swipe gesture to navigate to the next page.
  void _onSwipeLeft() {
    if (currentPage < children.length - 1) {
      onPageChanged(currentPage + 1);
    }
  }

  /// Handles the swipe gesture to navigate to the previous page.
  void _onSwipeRight() {
    if (currentPage > 0) {
      onPageChanged(currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          final swipeVelocity = details.velocity.pixelsPerSecond.dx;

          if (swipeVelocity > 800.0) {
            _onSwipeRight(); // Swipe right
          } else if (swipeVelocity < -800.0) {
            _onSwipeLeft(); // Swipe left
          }
        },
        child: CustomIndexedStack(
          index: currentPage,
          children: children,
        ),
      ),
    );
  }
}
