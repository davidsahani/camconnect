import 'package:flutter/material.dart';

/// A custom layout widget that swaps between Row and Column based on a boolean condition.
///
/// The `SwapLayout` widget provides a simple way to switch between Row and Column layouts
/// depending on the value of the `swap` parameter. When `swap` is `true`, it arranges its
/// children horizontally in a Row, and when `swap` is `false`, it arranges its children
/// vertically in a Column.
///
/// Example:
///
/// ```dart
/// SwapLayout(
///   swap: true, // Arrange children in a Row
///   children: [
///     Container(width: 100, height: 100, color: Colors.red),
///     Container(width: 100, height: 100, color: Colors.blue),
///     Container(width: 100, height: 100, color: Colors.green),
///   ],
///   mainAxisAlignment: MainAxisAlignment.center,
/// )
/// ```
class SwapLayout extends StatelessWidget {
  /// Creates a layout that swaps between Row and Column based on a boolean condition.
  ///
  /// The `swap` parameter determines whether the layout should use Row or Column.
  /// When `swap` is `true`, it arranges its children horizontally in a Row,
  /// otherwise, it arranges its children vertically in a Column.
  ///
  /// The `children` parameter is a list of widgets that are to be arranged either
  /// horizontally or vertically based on the `swap` condition.
  ///
  /// The `mainAxisAlignment` parameter allows customization of the alignment of the children
  /// within the main axis (either horizontal or vertical) of the layout.
  const SwapLayout({
    super.key,
    required this.swap,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  /// Determines whether to arrange the children in a Row (true) or Column (false).
  final bool swap;

  /// The widgets to be arranged either horizontally or vertically based on the `swap` condition.
  final List<Widget> children;

  /// How the children should be placed along the main axis in the layout.
  ///
  /// For a Row layout, this property controls the horizontal alignment,
  /// while for a Column layout, it controls the vertical alignment.
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return swap
        ? Row(
            mainAxisAlignment: mainAxisAlignment,
            children: children,
          )
        : Column(
            mainAxisAlignment: mainAxisAlignment,
            children: children,
          );
  }
}
